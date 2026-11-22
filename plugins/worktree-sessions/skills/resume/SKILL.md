---
name: resume
description: Resume the Claude session of an issue or PR review started with the issue or pr-review skill, in its worktree. Run only when the user invokes it.
argument-hint: "<ISSUE-ID [part of the worktree path] | PR number or URL>"
disable-model-invocation: true
---

Run this Bash command once, on its own, as the bare name `ws-resume` (never by full path, chained or after `cd`):

    ws-resume $ARGUMENTS

It finds the worktree and opens its session in a Ghostty tab. Report the worktree in one line. When an issue has
several worktrees it lists them and fails: ask the user which one, then run `ws-resume <ISSUE-ID> <part of its path>`. When it prints a
command to run instead of opening a tab, give that command in a `bash` code block. If it fails, quote its error.
