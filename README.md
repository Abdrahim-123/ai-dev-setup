# ai-dev-setup

A token-efficient, 3-agent AI development workflow for Windows, combining **Claude Code**, **Gemini Pro** (via MCP), and **GitHub Copilot** with a persistent knowledge graph and automatic session handoff.

---

## Agents

| Agent | Role | How to use |
|-------|------|------------|
| **Claude Code** | Agentic edits, multi-file refactor, orchestration | Terminal (`claude`) |
| **Gemini Pro** | Large-context review, architecture audits | `/gemini-cli:ask-gemini "..."` |
| **GitHub Copilot** | Inline autocomplete, quick suggestions | VS Code editor pane |

---

## How it works

### Knowledge graph (`code-review-graph`)
A local SQLite graph of your codebase that updates automatically on every file save. Instead of scanning files with Grep/Glob, Claude Code queries the graph for callers, dependents, blast radius, and test coverage — saving tokens and providing structural context.

### Session handoff
- **On session end** — a `Stop` hook writes `SESSION_HANDOFF.md` with the git branch, recently modified files, graph status, and resume instructions for all three agents.
- **On session start** — a `SessionStart` hook reads the handoff file and prints a summary banner so Claude Code picks up exactly where the last session left off.

### Hooks (auto-triggered)
| Hook | Trigger | Action |
|------|---------|--------|
| `SessionStart` | Claude Code opens | Print handoff banner + graph status |
| `Stop` | Claude Code closes | Write `SESSION_HANDOFF.md` |
| `PostToolUse` | Any Edit/Write/Bash | Incrementally update the graph |
| `PreCommit` | `git commit` | Run change detection with risk scores |

---

## Project structure

```
.claude/
  hooks/
    session-start.ps1      # Banner + handoff display on startup
    generate-handoff.ps1   # Writes SESSION_HANDOFF.md on stop
  skills/
    explore-codebase.md    # Graph-first exploration skill
    debug-issue.md         # Debugging workflow skill
    refactor-safely.md     # Blast-radius-aware refactor skill
    review-changes.md      # Code review skill
  settings.json            # Hook configuration
  settings.local.json      # Local permission overrides (gitignored)
.github/
  copilot-instructions.md  # Copilot coding standards + handoff ref
.mcp.json                  # Project-level MCP servers (gemini-cli, code-review-graph)
CLAUDE.md                  # Claude Code session instructions
AGENTS.md                  # Graph MCP tool reference (all agents)
GEMINI.md                  # Gemini-specific graph instructions
setup.ps1                  # One-time setup script
```

---

## Setup (first time)

### Prerequisites
- Python 3.x with pip
- Node.js + npx
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- VS Code with GitHub Copilot extension

### Install

```powershell
# 1. Install the knowledge graph tool
pip install code-review-graph

# 2. Configure for Claude Code (sets up .mcp.json, hooks, skills)
code-review-graph install --platform claude-code

# 3. Build the initial graph
code-review-graph build

# 4. Register Gemini MCP at user level (available in all projects)
claude mcp add gemini-cli -s user -- npx -y gemini-mcp-tool
```

> **Windows note:** If `code-review-graph` is not found after install, add the Python Scripts folder to your PATH:
> ```powershell
> $p = "$env:APPDATA\Python\Python314\Scripts"
> [Environment]::SetEnvironmentVariable("PATH", "$([Environment]::GetEnvironmentVariable('PATH','User'));$p", "User")
> ```
> Then restart your terminal.

### Set your Gemini API key

```powershell
[Environment]::SetEnvironmentVariable("GOOGLE_API_KEY", "your-key-here", "User")
```

Get a key from [Google AI Studio](https://aistudio.google.com/app/apikey). Restart Claude Code after setting it.

---

## Daily workflow

1. Open Claude Code in your project — the `SessionStart` hook shows any pending handoff.
2. Use graph MCP tools first before reading files (see `AGENTS.md` for tool reference).
3. Work normally — the graph updates automatically on every file change.
4. Close Claude Code — the `Stop` hook writes `SESSION_HANDOFF.md` for next time.

### Resuming with Gemini
```
/gemini-cli:ask-gemini "Read SESSION_HANDOFF.md and continue pending work"
```

### Resuming with Copilot Chat
```
@workspace #file:SESSION_HANDOFF.md Please continue from the pending items.
```

---

## Gitignored files

| Path | Reason |
|------|--------|
| `SESSION_HANDOFF.md` | Session-specific, regenerated each time |
| `.code-review-graph/` | Local graph database, rebuilt from source |
| `.claude/settings.local.json` | Machine-specific permission overrides |
| `.env`, `.env.*` | Secrets |
