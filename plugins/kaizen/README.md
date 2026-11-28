# kaizen

Raph's configuration-layer harness for Claude Code: one way of working that routes each task (create, fix, review,
maintain, write, explore) to its workflow, with rules that improve from reviews and corrections. The design is in
[`docs/specs/2026-11-28-harness-design.md`](../../docs/specs/2026-11-28-harness-design.md).

## State

Skeleton. It:

- prints `rules/core.md` (asking, simplicity, enforcement, git, memory, documents) and `rules/communication.md` (the
  reply style, adapted from i-have-adhd: see `NOTICE.md`) from a classic `SessionStart` hook, so the rules reach every
  conversation, again after each compaction, including in Team and Enterprise organizations, whose security plugin
  skips a mod's prompt hooks;
- answers, from a mod (a TypeScript hooks module), `/kaizen doctor` with its version, whether its rules file is
  there, and whether `gh` is found.

## Requirements

Claude Code 2.1.311 or later (mods load with no setting there).

## Install

    claude plugin marketplace add rlemaitre/claude-plugins
    claude plugin install kaizen@rlemaitre

## Develop

    claude plugin test plugins/kaizen        # mod tests
    tests/kaizen_test.sh                     # SessionStart hook tests
    claude plugin validate plugins/kaizen    # what the engine will load or refuse
    claude --plugin-dir plugins/kaizen       # a session with this folder loaded
