# claude-plugins

Raph's personal [Claude Code](https://code.claude.com) plugin marketplace.

## Plugins

| Plugin | What | Upstream |
|---|---|---|
| `productivity` | Anthropic's productivity plugin (tasks, memory, daily updates) without bundled MCP servers: it uses the connectors already configured in Claude Code. See `plugins/productivity/NOTICE.md`. | [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins/tree/main/productivity) (Apache-2.0) |
| `kitty-image` | hood's kitty-image plugin (inline images in kitty-graphics terminals) without its `prompt.compose` hook, which the built-in `cc-plugin-sec-default` skips in Team and Enterprise organizations. See `plugins/kitty-image/NOTICE.md`. | [hood/claude-kitty-image](https://github.com/hood/claude-kitty-image) (MIT) |
| `md-show` | Shows a Markdown file as a readable HTML page, with Mermaid diagrams, in a terminal-browser split. Needs pandoc, mmdc and terminal-browser, and a sandbox exclusion: see `plugins/md-show/README.md`. | none (own plugin) |
| `intellij` | Hooks that keep the `.idea` files IntelliJ rewrites on its own out of Claude's commits, and notify you when IntelliJ waits for you to approve a run configuration. See `plugins/intellij/README.md`. | none (own plugin) |
| `worktree-sessions` | `/worktree-sessions:issue`, `pr-review` and `resume`: start a Linear issue or a PR review in its own worktree and Claude session (Ghostty tab, IntelliJ), and resume it later. See `plugins/worktree-sessions/README.md`. | none (own plugin) |
| `pr-flow` | `/pr-flow:pr-gate`, `pr-babysit`, `pr-review-guide` and `review-feedback`: a pre-PR gate with reviews and a comprehension check, a PR babysitter, review guides, and a monthly loop that turns repeated review comments into rules. See `plugins/pr-flow/README.md`. | none (own plugin) |
| `office` | Skill `xlsx-numbers`: read, write and verify .xlsx files viewed in Apple Numbers, without Excel or LibreOffice. Needs uv: see `plugins/office/README.md`. | none (own plugin) |
| `kaizen` | Raph's harness: one way of working with Claude Code that routes each task (create, fix, review, maintain, write, explore) to its workflow. Early skeleton: injects its rules and answers `/kaizen doctor`. See `plugins/kaizen/README.md`. | none (own plugin) |

## Install

    claude plugin marketplace add rlemaitre/claude-plugins
    claude plugin install productivity@rlemaitre
    claude plugin install kitty-image@rlemaitre
    claude plugin install md-show@rlemaitre
    claude plugin install intellij@rlemaitre
    claude plugin install worktree-sessions@rlemaitre
    claude plugin install pr-flow@rlemaitre
    claude plugin install office@rlemaitre
    claude plugin install kaizen@rlemaitre

## Keeping copies in sync with upstream

Every Monday, `.github/workflows/upstream-check.yml` runs `scripts/check-upstream.sh` and opens an issue when an
upstream plugin folder changed (it compares git tree hashes, so only real content changes count).

To sync a plugin:

1. Read the upstream diff for the plugin folder.
2. Copy the upstream folder over `plugins/<name>/`, keeping the changes listed in its `NOTICE.md` (for `productivity`:
   no `.mcp.json`, the `CONNECTORS.md` wording; for `kitty-image`: no `prompt.compose` hook, no `marketplace.json`,
   the README install lines, the `plugin.json` description).
3. Update `tree=` in `plugins/<name>/.upstream` and the version line in `NOTICE.md`.
4. Run `tests/check-upstream_test.sh` and `scripts/check-upstream.sh` (it must say "up to date").

## Tests

    tests/check-upstream_test.sh
    tests/worktree-sessions_test.sh
    tests/pr-flow_test.sh
    tests/kaizen_test.sh
