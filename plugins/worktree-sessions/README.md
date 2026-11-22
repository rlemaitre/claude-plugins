# worktree-sessions

Start each piece of work in its own git worktree and Claude session, from any Claude session:

| Skill | Command it runs | What it does |
|---|---|---|
| `/worktree-sessions:issue [--idea] ABC-123 [description]` | `ws-issue` | Takes the Linear issue (assigns it if nobody has it, Todo/Backlog to In Progress), creates `<gh-user>/<issue-id>-<slug>` with worktrunk, writes a brief, and opens a session in auto mode that analyzes the issue, then brainstorms the open questions with you. `--idea` also opens IntelliJ on the worktree and the brief. |
| `/worktree-sessions:pr-review 42` | `ws-pr-review` | Creates the PR worktree, opens IntelliJ, and runs a read-only pre-review (what it does, where to start reading, points of vigilance, findings, questions) into a Markdown file, then resumes that session in plan mode. |
| `/worktree-sessions:resume ABC-123 [pick]` or `42` | `ws-resume` | Finds the worktree of an issue or PR and continues its session (Claude's picker when there are several). |

The skills only run when you invoke them. The `ws-*` commands are on the Bash tool's `PATH` while the plugin is
enabled. New sessions open in a Ghostty tab named after the issue or PR when Claude runs inside Ghostty; anywhere else,
the command prints what to run.

## Config

Optional: a `.worktree-sessions` file in the checkout or any folder above it (a project root that holds the checkout
and its worktrees, for example). `KEY=value` lines, read as text, never run. Relative paths are relative to the file.

```sh
NOTES_DIR=02_notes                # brainstorm results (default: <git common dir>/worktree-sessions/notes)
BRIEFS_DIR=01_sources/briefs      # issue session briefs (default: .../worktree-sessions/briefs)
REVIEWS_DIR=02_notes/reviews      # pre-reviews (default: .../worktree-sessions/reviews)
REVIEW_RULES="01_sources/review-rules.md repo/.claude/rules"  # files or folders the pre-review checks, every one
EXTRA_DIRS=01_sources             # more folders the sessions may read (--add-dir)
```

Lists are separated by spaces, so paths cannot contain spaces. The pre-review always reads `REVIEW.md` and
`CLAUDE.md` at the repository root when they exist.

## Requirements

`git`, `gh` (logged in), [worktrunk](https://worktrunk.dev) (`wt`), `jq`, `perl`, `python3` and `uuidgen`;
[`linear-cli`](https://crates.io/crates/linear-cli) for issues; [`gum`](https://github.com/charmbracelet/gum) to pick
among several worktrees in a terminal; Ghostty and the IntelliJ `idea` launcher are optional.

## Sandbox

`gh`, `linear-cli`, `wt` and `osascript` need the network or write outside the checkout. Exclude the commands in
`settings.json`:

```json
{
  "sandbox": {
    "excludedCommands": ["ws-issue *", "ws-pr-review *", "ws-resume *"]
  }
}
```

The entries match the text of the call, so the skills run the bare commands on their own.

## Tests

    tests/worktree-sessions_test.sh

It runs the commands against throwaway repositories with fake `gh`, `linear-cli`, `wt`, `osascript`, `idea` and
`claude`.
