---
name: md-show
description: Show a Markdown document (a plan, a spec, a report) to the user as a readable HTML page in a terminal-browser split. Use when the user asks to see, show, open or preview a Markdown file, or after writing a document they should read.
---

# md-show

Run `md-show <file.md>` with the Bash tool. It renders the file with pandoc to one styled HTML page, turns Mermaid code
blocks into inline SVG, and opens the page in a terminal-browser split (a new tab when a split is already open).

- Run it as a command on its own, as the bare name `md-show`: never chained with `;`, `&&` or `|`, never after `cd`,
  never by full path. Only that form matches a `"md-show *"` entry in `sandbox.excludedCommands`; pandoc, mmdc and
  terminal-browser cannot run inside the sandbox.
- Then give the file path in the reply as usual: the page is a view, the Markdown file stays the source.
- Showing the same file again overwrites its page, so run it again after each edit the user should see.
- The page is one column of about 66 characters. Prefer top-down Mermaid flows (`flowchart TD`) or at most 4 nodes per
  row.
- If a Mermaid diagram fails to render, md-show prints a warning and shows it as code: fix the diagram and run again.
