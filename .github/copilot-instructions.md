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