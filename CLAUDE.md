# claude-plugins

Claude Code plugin marketplace. One directory per plugin under `plugins/`, listed in `.claude-plugin/marketplace.json`.

## Rules

- The entry `name` in `marketplace.json` and the `name` in `plugin.json` must be identical.
- Relative `source` paths start at the repo root (`./plugins/<plugin>`), never `..`.
- Skill names must not collide with Anthropic's built-in skills (`xlsx`, `docx`, `pptx`, `pdf`, `docs`): a collision
  confuses triggering.
- Personal-only plugins (anything touching mail, calendar, iCloud, personal files) stay out of plugins meant for the
  work machine.
- Bump `version` in `plugin.json` when a change should reach installed copies.

## Commands

    claude plugin validate .                     # marketplace
    claude plugin validate ./plugins/<plugin>    # one plugin

Tests and per-plugin commands: see `README.md` and each `plugins/<plugin>/README.md`.
