#Requires -Version 5.1
<#
.SYNOPSIS
  Sets up the 3-agent AI dev workflow for a project.
  Run once from the project root: powershell -File setup.ps1
#>

$ErrorActionPreference = "Stop"
$env:PYTHONUTF8 = "1"

Write-Host ""
Write-Host "========================================="
Write-Host "  3-Agent AI Dev Setup"
Write-Host "  Claude Code + Gemini + GitHub Copilot"
Write-Host "========================================="
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Fix PATH for code-review-graph on Windows
# ---------------------------------------------------------------------------
Write-Host "[1/7] Checking PATH for code-review-graph..."
$scriptsPath = "$env:APPDATA\Python\Python314\Scripts"
if (Test-Path $scriptsPath) {
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$scriptsPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$scriptsPath", "User")
        Write-Host "  Added $scriptsPath to permanent user PATH."
    }
    $env:PATH += ";$scriptsPath"
    Write-Host "  PATH OK."
} else {
    Write-Host "  Scripts path not found at $scriptsPath — skipping (adjust if your Python version differs)."
}

# ---------------------------------------------------------------------------
# 2. Install code-review-graph
# ---------------------------------------------------------------------------
Write-Host "[2/7] Installing code-review-graph..."
pip install code-review-graph --quiet
if ($LASTEXITCODE -ne 0) { Write-Error "pip install failed."; exit 1 }
Write-Host "  Done."

# ---------------------------------------------------------------------------
# 3. Write hook scripts
# ---------------------------------------------------------------------------
Write-Host "[3/7] Writing hook scripts..."
New-Item -ItemType Directory -Force -Path ".claude/hooks" | Out-Null

# session-start.ps1
@'
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗"
Write-Host "║           🧠  AI Dev Setup — Session Start           ║"
Write-Host "╚══════════════════════════════════════════════════════╝"
Write-Host ""

if (Test-Path "SESSION_HANDOFF.md") {
    Write-Host "📋 Pending handoff found — reading SESSION_HANDOFF.md..."
    Write-Host ""
    Get-Content "SESSION_HANDOFF.md" | Select-Object -First 20
    Write-Host ""
}

$graphCheck = Get-Command "code-review-graph" -ErrorAction SilentlyContinue
if ($graphCheck) {
    Write-Host "📊 Graph status:"
    code-review-graph status 2>$null
}

Write-Host ""
Write-Host "✅ Use graph MCP tools before reading files to save tokens"
Write-Host ""
'@ | Out-File -FilePath ".claude/hooks/session-start.ps1" -Encoding UTF8

# generate-handoff.ps1
# Note: inner @"..."@ heredoc markers are safe inside @'...'@ (single-quote heredoc)
@'
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
$branch = git branch --show-current 2>$null
if (-not $branch) { $branch = "unknown" }
$recentFiles = git diff --name-only HEAD 2>$null | Select-Object -First 10
if (-not $recentFiles) { $recentFiles = "No git changes detected" }
$graphStatus = code-review-graph status 2>$null
if (-not $graphStatus) { $graphStatus = "Graph not initialized" }

$content = @"
# Session Handoff — $timestamp
**Branch:** ``$branch``

---

## Files Modified This Session
``````
$($recentFiles -join "`n")
``````

---

## What Was Worked On
<!-- Update manually before closing if needed -->

## Pending / Next Steps
<!-- Add pending tasks here -->

---

## Graph Status
``````
$graphStatus
``````

---

## Resume Instructions

### For Claude Code (next session):
SessionStart hook will display this automatically.

### For Gemini Pro:
/gemini-cli:ask-gemini "Read SESSION_HANDOFF.md and continue pending work"

### For GitHub Copilot Chat:
@workspace #file:SESSION_HANDOFF.md Please continue from the pending items.
"@

$content | Out-File -FilePath "SESSION_HANDOFF.md" -Encoding UTF8

Write-Host ""
Write-Host "✅ SESSION_HANDOFF.md written — all agents can resume from here"
Write-Host ""
'@ | Out-File -FilePath ".claude/hooks/generate-handoff.ps1" -Encoding UTF8

Write-Host "  Done."

# ---------------------------------------------------------------------------
# 4. Write CLAUDE.md (project instructions only)
#    code-review-graph install will append its MCP tools section below
# ---------------------------------------------------------------------------
Write-Host "[4/7] Writing CLAUDE.md..."
if (-not (Test-Path "CLAUDE.md")) {
@'
# Project Intelligence — Claude Code

## Session Start Checklist
1. Check SESSION_HANDOFF.md for pending work from last session
2. Use graph MCP tools before reading any files — avoids token waste
3. Consult PROJECT_STRUCTURE.md for architecture orientation

---

## Multi-Agent Handoff Protocol

| Agent          | Role                               | How to invoke                         |
|----------------|------------------------------------|---------------------------------------|
| Claude Code    | Agentic edits, multi-file refactor | You are here                          |
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
- Do not commit SESSION_HANDOFF.md (it is gitignored)
'@ | Out-File -FilePath "CLAUDE.md" -Encoding UTF8
    Write-Host "  Created CLAUDE.md."
} else {
    Write-Host "  CLAUDE.md already exists — skipping (code-review-graph will append its MCP section)."
}

# ---------------------------------------------------------------------------
# 5. Write .github/copilot-instructions.md
# ---------------------------------------------------------------------------
Write-Host "[5/7] Writing Copilot instructions..."
New-Item -ItemType Directory -Force -Path ".github" | Out-Null
if (-not (Test-Path ".github/copilot-instructions.md")) {
@'
# GitHub Copilot Instructions

## Project Context
This project uses a 3-agent AI setup:
- Claude Code (terminal) — agentic edits and refactoring
- Gemini Pro (via MCP) — large-context analysis and code review
- GitHub Copilot (here) — inline autocomplete and quick suggestions

## Coding Standards
- Write tests for all new functions
- Follow existing file/folder naming conventions
- Document public APIs with docstrings
- No hardcoded secrets — use environment variables

## Handoff
When asked to continue work, reference SESSION_HANDOFF.md for context from the
last Claude Code or Gemini session:
@workspace #file:SESSION_HANDOFF.md
'@ | Out-File -FilePath ".github/copilot-instructions.md" -Encoding UTF8
    Write-Host "  Created .github/copilot-instructions.md."
} else {
    Write-Host "  Copilot instructions already exist — skipping."
}

# ---------------------------------------------------------------------------
# 6. Update .gitignore
# ---------------------------------------------------------------------------
Write-Host "[6/7] Updating .gitignore..."
$requiredEntries = @(
    "SESSION_HANDOFF.md",
    ".code-review-graph/",
    ".claude/settings.local.json"
)
if (Test-Path ".gitignore") {
    $existing = Get-Content ".gitignore" -Raw
    $missing = $requiredEntries | Where-Object { $existing -notlike "*$_*" }
    if ($missing) {
        "`n# AI dev setup" | Add-Content ".gitignore"
        $missing | Add-Content ".gitignore"
    }
} else {
    @(
        "# AI dev setup",
        "SESSION_HANDOFF.md",
        ".code-review-graph/",
        ".claude/settings.local.json"
    ) | Out-File ".gitignore" -Encoding UTF8
}
Write-Host "  Done."

# ---------------------------------------------------------------------------
# 7. Run code-review-graph install
#    Creates: .mcp.json, .claude/settings.json, .claude/skills/, AGENTS.md,
#             GEMINI.md, .cursorrules, .windsurfrules
#             Also appends MCP tools section to CLAUDE.md
# ---------------------------------------------------------------------------
Write-Host "[7/7] Running code-review-graph install..."
code-review-graph install --platform claude-code
if ($LASTEXITCODE -ne 0) { Write-Error "code-review-graph install failed."; exit 1 }
Write-Host "  Done."

# ---------------------------------------------------------------------------
# Patch settings.json — add SessionStart PS1 banner + Stop handoff hook
# (code-review-graph install overwrites settings.json with its own hooks;
#  we merge our custom hooks back in here)
# ---------------------------------------------------------------------------
Write-Host "Patching .claude/settings.json with handoff hooks..."
$settingsPath = ".claude/settings.json"
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

$psStartHook = [PSCustomObject]@{
    command = "powershell -File .claude/hooks/session-start.ps1"
    timeout = 10000
}
$settings.hooks.SessionStart = @($psStartHook) + @($settings.hooks.SessionStart)

$stopHook = [PSCustomObject]@{
    command = "powershell -File .claude/hooks/generate-handoff.ps1"
    timeout = 10000
}
$settings.hooks | Add-Member -NotePropertyName "Stop" -NotePropertyValue @($stopHook) -Force

$settings | ConvertTo-Json -Depth 10 | Out-File $settingsPath -Encoding UTF8
Write-Host "  Done."

# ---------------------------------------------------------------------------
# Build the graph
# ---------------------------------------------------------------------------
Write-Host "Building knowledge graph..."
code-review-graph build
Write-Host "  Done."

# ---------------------------------------------------------------------------
# Register Gemini MCP at user level (available in all projects)
# ---------------------------------------------------------------------------
Write-Host "Registering Gemini MCP at user level..."
claude mcp add gemini-cli -s user -- npx -y gemini-mcp-tool
Write-Host "  Done."

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "========================================="
Write-Host "  Setup complete!"
Write-Host "========================================="
Write-Host ""
Write-Host "Files created:"
Write-Host "  .claude/hooks/session-start.ps1"
Write-Host "  .claude/hooks/generate-handoff.ps1"
Write-Host "  .claude/settings.json  (hooks: SessionStart, Stop, PostToolUse, PreCommit)"
Write-Host "  .claude/skills/        (explore, debug, refactor, review)"
Write-Host "  .mcp.json              (gemini-cli + code-review-graph MCP servers)"
Write-Host "  CLAUDE.md"
Write-Host "  AGENTS.md / GEMINI.md"
Write-Host "  .github/copilot-instructions.md"
Write-Host "  .gitignore             (updated)"
Write-Host ""
Write-Host "Required manual steps:"
Write-Host "  1. Set your Gemini API key (once, permanent):"
Write-Host '     [Environment]::SetEnvironmentVariable("GOOGLE_API_KEY", "your-key", "User")'
Write-Host "     Get a key at: https://aistudio.google.com/app/apikey"
Write-Host ""
Write-Host "  2. Restart Claude Code to load the new MCP servers."
Write-Host ""
Write-Host "  3. Install the GitHub Copilot extension in VS Code if not already installed."
Write-Host ""
