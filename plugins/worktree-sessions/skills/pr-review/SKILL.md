---
name: pr-review
description: Check out a GitHub PR in its own worktree and start a read-only Claude pre-review of it, followed by a plan-mode session to discuss it. Run only when the user invokes it.
argument-hint: "<PR number or URL>"
disable-model-invocation: true
---

Run this Bash command once, on its own, as the bare name `ws-pr-review` (never by full path, chained or after `cd`):

    ws-pr-review $ARGUMENTS

It creates the PR worktree, opens IntelliJ on it and starts the pre-review in a Ghostty tab. Report its output to the
user in a few lines: the worktree and where the pre-review will be written. When it prints a command to run instead
of opening a tab, give that command in a `bash` code block.

Do not write the review yourself in this session. If the command fails, quote its error and stop.
