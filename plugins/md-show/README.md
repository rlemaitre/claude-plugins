# md-show

Shows a Markdown file as a readable HTML page in a [terminal-browser](https://terminal-browser.com/) split, next to
the terminal. Mermaid code blocks become inline SVG, so the page runs no script. Where terminal-browser cannot display
(a terminal without the kitty graphics protocol, Claude's desktop app), the page opens in the default browser.

- `bin/md-show <file.md>`: on the Bash tool's `PATH` while the plugin is enabled.
- `skills/md-show`: tells Claude when and how to run it, how to draw diagrams, and the look of one-off HTML pages.
- `assets/`: the pandoc template (light and dark themes, one 66ch column), the Mermaid filter and its config.

## Requirements

On `PATH`: `pandoc`, `mmdc` (`@mermaid-js/mermaid-cli`) and `terminal-browser`, or `open` / `xdg-open` for the browser
fallback. The page uses the Archivo,
Atkinson Hyperlegible Next and Geist Mono fonts when installed, and falls back to system fonts.

## Sandbox

pandoc, mmdc and terminal-browser cannot run inside Claude Code's sandbox. Exclude the command in `settings.json`:

```json
{
  "sandbox": {
    "excludedCommands": ["md-show *", "terminal-browser *"]
  }
}
```

The entry matches the text of the call, so Claude must run the bare `md-show <file.md>` on its own. The skill says so.

## Output

Pages go to `${XDG_CACHE_HOME:-~/.cache}/md-show/`, one per source path, so showing a file again overwrites its page.
