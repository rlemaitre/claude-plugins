# kitty-image

A Claude Code mod that lets Claude show PNG and SVG images inline in your terminal, using the kitty graphics protocol. Claude writes SVG on the fly, or renders a plot or diagram to a file (graphviz, gnuplot, matplotlib, ...), calls the `show_image` tool, and the picture is drawn right under the tool call. Claude only gets a one-line confirmation back, so images cost no context.

## Install

At the prompt of a Claude Code terminal session:

```
/plugin marketplace add rlemaitre/claude-plugins
/plugin install kitty-image@rlemaitre
```

From a shell:

```
claude plugin marketplace add rlemaitre/claude-plugins
claude plugin install kitty-image@rlemaitre
```

## Tool

`mcp__kitty-image__show_image`

| Arg | Required | Default |
|---|---|---|
| `svg` | one of `svg`/`path` | raw SVG markup, rasterized with `rsvg-convert` |
| `path` | one of `svg`/`path` | absolute path of a PNG or SVG (max 2 MiB) |
| `background` | no | SVG only, e.g. `white`; default transparent |
| `columns` | no | 80 (max 255) |
| `rows` | no | keeps the aspect ratio |
| `alt` | no | file name; shown where images can't be drawn |

## Behavior

- Adds no system prompt section (see `NOTICE.md`): the tool's own description tells Claude to draw charts and diagrams instead of ASCII art. For a stronger nudge, add a short section to your `CLAUDE.md`.
- After sending a picture, the mod checks it was actually drawn. If the terminal only shows the `alt` text, the tool returns an error so Claude falls back to text instead of describing a chart nobody can see.

## Requirements

`rsvg-convert` for SVG (`brew install librsvg`).

## Terminal support

Claude Code draws images in kitty and Ghostty (and iTerm2 3.5+ in fullscreen rendering). Inside tmux it needs:

```
set -g allow-passthrough on
set -g focus-events on
```

Claude Code recognizes terminals by name. If yours supports kitty graphics but isn't recognized (you see the dim `alt` text instead of the picture), force it before starting Claude Code:

```sh
export CLAUDE_CODE_FORCE_TERMINAL_IMAGES=1
```

## License

MIT
