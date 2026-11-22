# pr-flow

Skills for the life of a pull request, from the last commit to the review lessons learned:

| Skill | When | What it does |
|---|---|---|
| `/pr-flow:pr-gate` | The code works, before the PR | Structures the commits, runs the repository's review skills and a fresh-agent review in parallel, fixes the findings you pick, checks that you understand the diff (an examiner agent asks open questions and grades your answers), then opens a draft PR. Runs only when you invoke it. |
| `/pr-flow:pr-babysit [PR]` | The PR is open, `/loop /pr-flow:pr-babysit` | One pass: reads CI failures and new review comments (bots and humans), fixes what is clear in local commits for you to push, and drafts replies. Never pushes, posts or resolves anything. |
| `/pr-flow:pr-review-guide [PR]` | A PR with real design choices | Writes or updates a PR description that explains the design before the diff: why, why here, how it works, review order, points to check. |
| `/pr-flow:review-feedback [period]` | Once a month | Mines the review comments you received and gave, clusters the repeated ones, and proposes where each should become automatic (linter, team rule, docs, your own review rules). Writes a report; applies nothing without your go-ahead. |

`bin/pr-flow-config` (on the Bash tool's `PATH` while the plugin is enabled) prints what the skills need: the
repository, its default branch and your GitHub login from `gh`, and `REVIEWS_DIR` and `REVIEW_RULES` from the
`.worktree-sessions` file.

## Config

The skills share the optional `.worktree-sessions` file with the worktree-sessions plugin: the first one found in the
checkout or any folder above it. `KEY=value` lines, read as text, never run; relative paths are relative to the file.

```sh
REVIEWS_DIR=02_notes/reviews                     # review-feedback reports (default: <git common dir>/worktree-sessions/reviews)
REVIEW_RULES="01_sources/review-rules.md repo/.claude/rules"   # your review rules: pr-gate checks every one
```

The first file in `REVIEW_RULES` is your personal rules file, where `review-feedback` proposes to add new rules.

## How the skills use the repository

They use what the repository already has, and fall back to plain `gh` and git:

- **Review skills** (`.claude/skills/*review*/SKILL.md`, or under `.cursor/skills/`): `pr-gate` follows those whose
  scope covers the diff, in report-only mode.
- **Commit structuring and PR opening skills**: followed when present; otherwise `pr-gate` separates mechanical and
  behavior commits itself and opens the PR with `gh pr create --draft`.
- **CI**: a skill for reading CI results when present; otherwise `gh pr checks` and `gh run view --log-failed`.
- **Build and test commands**: from the repository's `CLAUDE.md`.
- **gh-stack** branches: pushed with `gh stack push`.

## Requirements

`git`, `gh` (logged in). `pr-babysit` runs best under `/loop`. `pr-review-guide` shows drafts with `md-show` when the
md-show plugin is installed.

## Sandbox

`gh` needs the network. Exclude the config command in `settings.json`:

```json
{
  "sandbox": {
    "excludedCommands": ["pr-flow-config"]
  }
}
```

The skills' own `gh` calls go through your usual permission and sandbox rules.

## Tests

    tests/pr-flow_test.sh
