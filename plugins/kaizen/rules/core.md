kaizen is active.

## Asking

1. Facts you can look up (code, project files, docs, memory) you look up. They never become a question.
2. Decisions and real unknowns you ask about. Do not guess what Raph wants.
3. Questions are batched: one message at the start of a phase, not one at a time during the work. Each question
   carries your recommendation, so "yes" is a full answer.
4. Never ask the same thing twice: answers are recorded, and a recurring answer becomes a rule proposal.

## Simplicity

1. Don't assume. Don't hide confusion. Surface tradeoffs
2. Minimum code that solves the problem. Nothing speculative
3. Touch only what you must. Clean up only your own mess
4. Define success criteria. Loop until verified

Simplicity comes first in all the code you write and in every review, whatever the skill or plan you follow.

- Write the simplest code a teammate can read in one sitting: no class, type, parameter, default or abstraction
  that no caller needs, no generality for later, plain local state over indirection.
- In a review, unneeded complexity is a real finding, not polish: name the simpler form that does the same job.
- When you hand code or a review to a subagent, put this rule in its brief.

Before writing code, take the first option that fully works:

1. Does it need to exist?
2. Is it already in the codebase?
3. The standard library, or a platform feature?
4. An installed dependency?
5. One line?
6. Only then, the minimum code that works.

Never cut: validation at trust boundaries, error handling that prevents data loss, security, accessibility, anything
Raph asked for. Each reply that changed code ends with what was skipped or not checked, and any risk.

## Enforcement

Anything that can be enforced automatically is. Preferred order: types, linting, tests, agent rules, documentation.
When you find a problem (in a review, a fix, a correction), also ask which is the cheapest level that would have
caught it, and propose the rule there.

## Work

- **All English**: Code, comments, documentation, commits, configs, errors, tests

When reviewing a branch, review the FULL diff against the base branch (not just
recent commits or a sampled subset of files); explicitly enumerate all changed
files first

## Git and PRs

- Commit messages: `<type>: <description>`, types feat, fix, refactor, docs, test, chore, perf, ci. No attribution
  lines (Co-Authored-By, "Generated with").
- When creating PRs, organize work into logical separate commits BEFORE opening
  the PR (don't squash everything into one commit)
- PR descriptions must cover the entire branch diff, not just the latest commit
- Never force-push; let the user push manually when force-push is needed
- After creating a PR, always output its size (files, lines added and deleted, from `git diff --numstat`):
  - the whole PR against its base: total, then production, tests and documentation
  - each commit, oldest first: total, production, tests and documentation

  Tests are files under test directories or named as tests (`src/test/`, `*Test.kt`, `*.test.ts`, `test_*.py`).
  Documentation is `*.md` and `docs/`. Production is everything else.

## Code intelligence

Prefer LSP over Grep/Glob/Read to understand code: it gives exact results, Grep gives text matches.

- `goToDefinition` / `goToImplementation`, `findReferences`, `workspaceSymbol`, `documentSymbol`, `hover`,
  `incomingCalls` / `outgoingCalls`
- Before renaming or changing a function signature, run `findReferences` to find every call site.
- Use Grep/Glob for discovery (finding files, comments, strings, config values); then navigate inside a file with LSP
  instead of reading it whole.
- After writing or editing code, check LSP diagnostics and fix type errors or missing imports immediately.

## Memory

Two stores, each for one kind of fact:

- Auto memory (`MEMORY.md`): how you should act every time. My preferences, corrections, recurring workflow steps.
- MemPalace: what happened or was decided. Decisions and their reasons, project facts, people, past sessions.

Recall:

- Before answering about past work, a prior decision, a project, a person or an earlier session, search MemPalace
  (`mempalace_search`, `mempalace_kg_query` for facts about an entity) and quote what it returns. Follow the
  `mempalace:mempalace-recall` skill.
- Do not search for work with no link to the past (a rename, a typo, a fresh feature).
- If the MemPalace tools are missing or fail, say so instead of answering from guesswork.

Saving:

- A decision, a project fact or a fact that changed goes to MemPalace: `mempalace_kg_add`, `mempalace_kg_supersede`
  when it replaces an older fact (object at most 128 characters), `mempalace_add_drawer` for longer text. Use the
  project's existing wing.
- A rule about how you should act goes to auto memory, never to both.

## Documents and images

In a kitty-graphics terminal, the kitty-image plugin's `show_image` tool draws images inline.

- When a chart, diagram, flow, layout or sketch explains better than text, draw it with `show_image`, not ASCII art.
- Hand-written `svg` for sketches and diagrams: explicit viewBox, a background color, readable font sizes. Render
  graphs and plots to a file (graphviz `dot -Tpng`, gnuplot) and pass its `path`.
- Keep the key facts in the text: the image supports the answer, it does not replace it.
- If `show_image` says the terminal cannot draw images, stop using it for the rest of the session.

Wrap Markdown prose at 120 columns (`[*.md] max_line_length` in `~/.editorconfig`).
A closer `.editorconfig` or the repo's own lint config wins. Code blocks and tables may be longer. When editing an
existing file, keep its line breaks: only wrap the lines you write or change, never rewrap a whole file.

- Write documents in Markdown, or in the format of the tool they live in (PR, Linear, Notion). Markdown is the
  source of truth: I can edit it, git diffs it, and agents read it cheaply.
- To show me one (a plan, a spec, a report), use the md-show plugin's skill, then give the path in the reply as usual.
  Its skill also covers diagrams and the look of the rare one-off HTML page.
