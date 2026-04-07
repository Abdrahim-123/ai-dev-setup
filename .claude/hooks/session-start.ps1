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