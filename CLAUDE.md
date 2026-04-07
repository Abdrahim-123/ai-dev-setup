# Project Intelligence — Claude Code

## Session Start Checklist
1. Check SESSION_HANDOFF.md for pending work from last session
2. Use graph MCP tools before reading any files — avoids token waste

---

## Project Structure
- Prefer graph MCP tools over raw file traversal (faster, fewer tokens)
- Use blast radius analysis before any refactor
- For full-codebase orientation, delegate to Gemini:
  /gemini-cli:ask-gemini "@src/ architecture overview"

---

## Multi-Agent Handoff Protocol

| Agent          | Role                               | How to invoke                         |
|----------------|------------------------------------|---------------------------------------|
| Claude Code    | Agentic edits, multi-file refactor | You're here                           |
| Gemini Pro     | Large-context review, arch audits  | /gemini-cli:ask-gemini "..."          |
| GitHub Copilot | Inline autocomplete                | VS Code editor pane (always-on)       |

On session end: SESSION_HANDOFF.md is auto-written by the Stop hook.
On session start: Read SESSION_HANDOFF.md before doing anything else.

---

## Coding Standards
- Write tests for all new functions
- Follow existing file/folder naming conventions
- Document public APIs with docstrings
- No hardcoded secrets — use environment variables

---

## Never Do
- Do not read entire directories without checking the graph first
- Do not modify .code-review-graph/graph.db manually
- Do not commit SESSION_HANDOFF.md (it's gitignored)

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Understanding blast radius of a change |
| `get_affected_flows` | Finding which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.
