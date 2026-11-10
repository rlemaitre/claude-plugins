# claude-plugins

Raph's personal [Claude Code](https://code.claude.com) plugin marketplace.

## Plugins

| Plugin | What | Upstream |
|---|---|---|
| `productivity` | Anthropic's productivity plugin (tasks, memory, daily updates) without bundled MCP servers: it uses the connectors already configured in Claude Code. See `plugins/productivity/NOTICE.md`. | [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins/tree/main/productivity) (Apache-2.0) |
| `kitty-image` | hood's kitty-image plugin (inline images in kitty-graphics terminals) without its `prompt.compose` hook, which the built-in `cc-plugin-sec-default` skips in Team and Enterprise organizations. See `plugins/kitty-image/NOTICE.md`. | [hood/claude-kitty-image](https://github.com/hood/claude-kitty-image) (MIT) |

## Install

    claude plugin marketplace add rlemaitre/claude-plugins
    claude plugin install productivity@rlemaitre
    claude plugin install kitty-image@rlemaitre

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
