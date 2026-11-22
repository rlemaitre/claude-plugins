#!/usr/bin/env bash
# PreToolUse hook on mcp__jetbrains__execute_run_configuration: IntelliJ asks for approval before it runs a
# configuration started over MCP (brave mode stays off), and the dialog is easy to miss behind the terminal.
# Shows a macOS notification with a sound, and a one-line reminder in Claude Code. Never blocks the tool.
set -euo pipefail

osascript -e 'display notification "Approve the run configuration in IntelliJ" with title "Claude Code" sound name "Glass"' \
  >/dev/null 2>&1 || true
echo '{"systemMessage": "IntelliJ is waiting for you to approve the run configuration."}'
