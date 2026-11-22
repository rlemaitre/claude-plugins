---
name: md-show
description: Show a Markdown document (a plan, a spec, a report) to the user as a readable HTML page in a terminal-browser split, or in the default browser where the terminal cannot display it. Use when the user asks to see, show, open or preview a Markdown file, after writing a document they should read, or before writing a one-off HTML page for them.
---

# md-show

Run `md-show <file.md>` with the Bash tool. It renders the file with pandoc to one styled HTML page, turns Mermaid code
blocks into inline SVG, and opens the page in a terminal-browser split (a new tab when a split is already open). Where
terminal-browser cannot display (no kitty graphics protocol, as in Claude's desktop app), it opens the page in the
default browser and says so.

- Run it as a command on its own, as the bare name `md-show`: never chained with `;`, `&&` or `|`, never after `cd`,
  never by full path. Only that form matches a `"md-show *"` entry in `sandbox.excludedCommands`; pandoc, mmdc and
  terminal-browser cannot run inside the sandbox.
- Then give the file path in the reply as usual: the page is a view, the Markdown file stays the source.
- Showing the same file again overwrites its page, so run it again after each edit the user should see.
- The page is one column of about 66 characters. Prefer top-down Mermaid flows (`flowchart TD`) or at most 4 nodes per
  row.
- If a Mermaid diagram fails to render, md-show prints a warning and shows it as code: fix the diagram and run again.

## Diagrams

Include a diagram when it explains better than text: a Mermaid code block (flows, sequences, states) or inline SVG.
md-show renders Mermaid to SVG, so the page needs no script.

## One-off HTML pages

Write raw HTML only for a page that needs custom layout or interaction; everything else is Markdown shown with
md-show. Give such a page the same look as `${CLAUDE_PLUGIN_ROOT}/assets/template.html` (read it for the colors):

- fonts: `"Archivo"` for titles, `"Atkinson Hyperlegible Next"` for text, `"Geist Mono"` for code, with system
  fallbacks;
- one column of about 66ch, 18px text;
- one accent color;
- light and dark themes through `prefers-color-scheme`.
