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