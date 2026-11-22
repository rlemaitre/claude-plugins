---
name: issue
description: Start work on a Linear issue in its own worktree, with a new Claude session that analyzes the issue and brainstorms it. Run only when the user invokes it.
argument-hint: "[--idea] <ISSUE-ID> [branch description...]"
disable-model-invocation: true
---

Run this Bash command once, on its own, as the bare name `ws-issue` (never by full path, chained or after `cd`):

    ws-issue $ARGUMENTS

It takes the issue in Linear, creates the worktree and writes the session brief, then opens the new session in a
Ghostty tab. Report its output to the user in a few lines: the Linear changes, the worktree, the brief and plan paths.
When it prints a command to run instead of opening a tab, give that command in a `bash` code block.

If it fails, quote its error and stop: do not create the worktree or the brief by hand.
