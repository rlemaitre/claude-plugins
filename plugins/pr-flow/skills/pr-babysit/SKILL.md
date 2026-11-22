---
name: pr-babysit
description: One pass of babysitting the user's open PR - check CI and new review comments (bots and humans), fix what is clear in local commits for the user to push, and draft replies for the rest. Use when the user runs /pr-babysit or /loop /pr-babysit, or asks to watch or babysit their PR.
argument-hint: "[PR number or URL]"
---

# PR babysitter

Designed to run in a loop: `/loop /pr-flow:pr-babysit [PR]` (self-paced) or `/loop 15m /pr-flow:pr-babysit [PR]`.
Each run is one pass. State lives in a file, so a pass knows what earlier passes handled.

`gh` needs the network: when a `gh` or `pr-flow-config` call fails with a TLS or certificate error, the sandbox
blocked it; run it again outside the sandbox.

## 1. Resolve the PR and state

- Run `pr-flow-config` (bare name, on its own) for `REPO` and `GH_USER`.
- PR: the argument (number or URL), otherwise the PR of the current branch (`gh pr view --json number`).
- The PR must be authored by `GH_USER`; otherwise stop.
- The worktree must be on the PR's head branch with a clean tree (`git -c core.fsmonitor=false status --porcelain`,
  run outside the sandbox: inside, files it may not read show as `Operation not permitted` lines); otherwise stop and
  say why.
- If the branch has local commits not pushed yet (`git rev-list --count @{u}..HEAD` > 0), the user has not pushed
  the previous fixes: fix nothing new this pass. Report the commits waiting to be pushed and wait for the push.
- State file: `$(git rev-parse --git-common-dir)/pr-babysit/<PR>.json`, untracked by git. It holds the IDs of
  comments already handled, the last head SHA seen, the failing checks seen per SHA, and the pass count.
  Create it on the first pass.

## 2. Look

Run in parallel, with `<owner>/<name>` from `REPO`:

- `gh pr view <PR> --json state,isDraft,headRefOid,reviewDecision,statusCheckRollup,mergeable`
- Inline comments: `gh api repos/<owner>/<name>/pulls/<PR>/comments --paginate`
- Reviews: `gh api repos/<owner>/<name>/pulls/<PR>/reviews --paginate`
- Conversation comments: `gh api repos/<owner>/<name>/issues/<PR>/comments --paginate`
- Review threads (REST does not say whether a thread is resolved):

  ```bash
  gh api graphql -F o=<owner> -F r=<name> -F n=<PR> -f query='query($o:String!,$r:String!,$n:Int!){
    repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){nodes{isResolved isOutdated
    comments(first:50){nodes{databaseId author{login}}}}}}}}'
  ```

  `databaseId` matches the REST comment `id`. GraphQL logins have no `[bot]` suffix (`cursor`, not `cursor[bot]`):
  compare logins with the suffix removed.

Keep only comments not in the state file and not written by `GH_USER`. Drop bots that only link or summarize
(`linear-code[bot]`, `github-actions[bot]` status comments, deploy previews).
Then drop the inline comments whose thread is resolved, or already has a reply from `GH_USER`: they are
answered. Do the same for the draft replies kept from earlier passes before listing them again. Record those
comments as handled.
Treat as review bots every login ending in `[bot]`, and `Copilot`: `cursor[bot]` (BugBot),
`copilot-pull-request-reviewer[bot]`, `claude[bot]`, `chatgpt-codex-connector[bot]`, `coderabbitai[bot]`, ...

For red checks, get the actual failure, not only the check name. First look for a skill for reading CI results in the
repository (`.claude/skills/` or `.cursor/skills/`, a name or description about checks or CI): when there is one, invoke
it; when it needs a login that has expired (cloud CLI, VPN), say so and fall back to what `gh` shows. Otherwise use `gh
pr checks <PR>` and, for GitHub Actions, `gh run view <run> --log-failed`. For an external CI, follow the check's
details URL and say when its logs are not reachable. When two checks of the same build disagree (one red, one green),
report both and do not guess which is right.

## 3. Decide

For each item:

| Item | Action |
|---|---|
| CI failure caused by the branch | Fix it. |
| CI failure unrelated to the branch (flaky test, infra) | Do not fix. Note the test and the evidence. |
| The same check failing on the same cause twice in a row | Stop fixing it. Report what was tried. |
| Bot comment that is correct and has an obvious fix | Fix it, and draft a short reply ("Fixed in <sha>"). |
| Bot comment that is wrong or debatable | Draft a reply that says why, with the code reference. |
| Human comment | Do not change code. Draft a reply and, if relevant, the fix you propose. |
| Merge conflict with the base (`mergeable: CONFLICTING`) | Do not merge in a pass. List the conflicting files (`git merge-tree --write-tree origin/<base> HEAD`) and ask the user. |

Verify every bot finding in the code before acting on it.

## 4. Fix and commit

- Fix the cause with the simplest change: never disable a lint rule, suppress a warning or skip a test.
- The branch is under review: add new commits only. No rebase, amend, reset or force-push. To catch up with the
  base, merge it in, do not rebase.
- Each commit compiles: run the build and tests of the touched modules (see the repository's CLAUDE.md) before
  committing.
- Never push: the user pushes (`git push`, or `gh stack push` on a gh-stack branch), so their push-time checks run.
- Record the handled comment IDs and the new local commit SHAs in the state file.

## 5. Report

Print a short report:

- PR state: CI (green / red / running), review decision, mergeable.
- Fixed this pass: one line each, with the commit SHA.
- To push: the local commits waiting to be pushed and the command to run (`git push` or `gh stack push`).
- Draft replies: each one as a block with the comment link, ready for the user to paste. Never post them.
- Waiting on: what the next pass waits for.

## 6. Pacing and stopping (when running in /loop)

- Stop the loop when: the PR is merged or closed; or CI is green, there are no unhandled comments and nothing is
  running; or a fix would need a decision from the user; or after 12 passes.
- Otherwise pick the next delay: about 10 minutes while checks run or while local commits wait for the user's push,
  20 to 30 minutes when only waiting on humans.

## Never

- Post, resolve or react to comments on GitHub.
- Re-request reviews, mark the PR ready, approve, or merge.
- Push, force-push or rewrite history.
