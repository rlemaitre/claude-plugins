# Notice

This plugin is a modified copy of the `kitty-image` plugin from
[hood/claude-kitty-image](https://github.com/hood/claude-kitty-image), version 0.1.1
(upstream repository tree `18fb703`, latest upstream commit `8dd889a`, 2026-11-13), licensed under the MIT License
(see `LICENSE`).

Changes from upstream:

- `hooks/register.tsx`: the `prompt.compose` hook and its `GUIDANCE` text removed. In Team and Enterprise
  organizations, the built-in `cc-plugin-sec-default` plugin runs before user plugins and keeps them out of the system
  prompt, so the hook never ran and every session started with a "prompt.compose hook was skipped" warning. The
  guidance lives in the user's `CLAUDE.md` instead; the tool's own description carries the same nudge.
- `.claude-plugin/plugin.json`: version `0.1.1-rlemaitre.1`; the description says SVG too.
- `README.md`: install from `rlemaitre/claude-plugins`; the Behavior section no longer mentions the system prompt
  section.
- The upstream `.claude-plugin/marketplace.json` is not copied: this repository's marketplace lists the plugin.

The `show_image` tool and its rendering are unchanged.
