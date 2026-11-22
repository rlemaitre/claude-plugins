# intellij

Two hooks for working with Claude Code next to IntelliJ.

## idea-guard

IntelliJ rewrites tracked `.idea/` files on its own, so a worktree often has `.idea` changes nobody asked for.
`hooks/idea-guard.sh` blocks a `git commit` that would include an `.idea` file Claude did not edit in this session.
It counts what is staged, plus what a `commit -a` or a broad `git add` (`-A`, `.`, `-u`, `.idea`) in the same command
would stage.

- A prompt that mentions `.idea` allows every `.idea` file for the rest of the session.
- The `.idea` files Claude edits with Edit, Write or NotebookEdit stay allowed.
- State lives in `${XDG_CACHE_HOME:-~/.cache}/claude-idea-guard/<session id>`.

Needs `jq`, `perl` and `git`.

## Run configuration reminder

IntelliJ asks for approval before it runs a configuration started over its MCP server
(`mcp__jetbrains__execute_run_configuration`), and the dialog is easy to miss behind the terminal.
`hooks/intellij-run-reminder.sh` shows a macOS notification with a sound and a one-line reminder in Claude Code. It
never blocks the tool. Off macOS, only the reminder shows.
