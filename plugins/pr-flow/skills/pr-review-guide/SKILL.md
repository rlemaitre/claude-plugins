---
name: pr-review-guide
description: Use when the user asks for a review guide, a document to ease code review, or a richer PR description, or when a PR with real design choices (state machine, concurrency, new pipeline stage, several commits to read one by one) needs more than a short summary.
argument-hint: "[PR number]"
---

# PR review guide

A PR description that lets a reviewer understand the design before reading the diff, for the PRs where a 3-line
summary is not enough. It extends the repository's PR format: when the repository has a skill or template for PR
descriptions (`open-pr` skill, `.github/pull_request_template.md`), keep its header lines and test plan. For small
PRs, follow that format alone.

`gh` needs the network: when a `gh` or `pr-flow-config` call fails with a TLS or certificate error, the sandbox
blocked it; run it again outside the sandbox.

## The guide's sections, in this order

Drop a section only when the PR has nothing for it. Aim for about 2 pages: each fact goes in one section only.

1. **Header lines**, as the repository's format writes them (issue links, `Fixes:`, `Depends on:`).
2. **Why**: the user-visible problem in 2-3 sentences, then what the PR does about it and every feature flag or
   condition that guards it.
3. **Why here**: why the change lives where it does and not in the obvious other places (client, endpoint, another
   stage). Argue from the code's structure: what is known at that point, what is not known yet. Name components, not
   files or line numbers.
4. **What changes**: one bullet per concern (activation, plumbing, new logic, refactors that keep behavior), not per
   file.
5. **How it works**: the mechanism a reviewer must hold in mind to read the diff. One or two Mermaid diagrams
   (`stateDiagram-v2` for a state machine, `sequenceDiagram` for signals between components), each starting with a
   `title:` frontmatter block.
6. **Review order**: a table, one row per commit, with the file to open first. Say which commit turns the behavior
   on, and which commits are mechanical.
7. **Points to check**: at most 5 numbered invariants a reviewer should verify (lost signals, ordering, the path with
   the feature off, shutdown, limits).
8. **Tests**: a table, one row per test file, saying what the file proves and how many tests it adds.
9. **Known limits** and **Follow-ups**, when there are any.
10. **Test plan**, as the repository's format writes it.

## Facts

- Diff against `origin/<base>` after `git fetch`: the local default branch is often stale.
- Every number, constant, name, test count and per-commit claim comes from the code or `git show --stat <commit>`,
  read in this session.
- Each word describes what the code does. A timeout that is skipped while a condition holds "is disabled", it does not
  "wait"; a check that runs on each signal does not "block". Reread every verb on timing and concurrency against the
  code.
- `[x]` only for what was run. Keep the author's existing ticks as they are.

## Updating an existing PR

1. Fetch the current body: `gh pr view <n> --json body -q .body`.
2. Merge, do not replace: keep the header links, known limits, follow-ups and the author's test plan. Keep every
   block a tool maintains (between marker comments, such as a CI or deployment block) byte for byte, where it was.
   Fold the old summary prose into the new sections.
3. Write the draft to the scratchpad. Show it with `md-show <file>` when the md-show plugin is installed, otherwise
   give its path, and wait for the user's go-ahead.
4. `gh pr edit <n> --body-file <file>`, then read the body back and diff it with the file (only a final newline may
   differ).
5. Before a later edit, fetch the body again: the user may have changed it in the GitHub UI.

Prose wraps at 120 columns. Tables, code blocks and tool-maintained blocks may be longer.
