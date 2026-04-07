# Install code-review-graph
pip install code-review-graph

# Configure for Claude Code
code-review-graph install --platform claude-code

# Build the graph
code-review-graph build

# Register Gemini MCP
claude mcp add gemini-cli -s user -- npx -y gemini-mcp-tool