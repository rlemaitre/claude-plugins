---
name: review-feedback
description: Monthly review-feedback loop - mine the review comments the user received and gave on the current repository over the last month, find the repeated ones, and propose where each should become automatic (review rule, linter, CLAUDE.md, memory). Use when the user runs /review-feedback or asks what keeps coming back in reviews.
argument-hint: "[period: 2026-09 or 30d]"
---

# Review-feedback loop

A comment that comes back in review is a rule nobody wrote down. Once a month, find those comments and propose
where each one should live so the next review catches it without a human.

This skill only writes a report. It changes no rule, config or code without the user's go-ahead.

`gh` needs the network: when a `gh` or `pr-flow-config` call fails with a TLS or certificate error, the sandbox
blocked it; run it again outside the sandbox.

## 1. Collect

Run `pr-flow-config` (bare name, on its own) for `REPO`, `GH_USER`, `REVIEWS_DIR` and `REVIEW_RULES`.
Period: the previous calendar month by default, or the argument: a month (`2026-09` is `2026-09-01..2026-09-30`) or a
number of days (`30d` is the 30 days up to today). `<from>..<to>` below are those dates.

- **Received**: PRs by `GH_USER` updated in the period:
  `gh search prs --repo <REPO> --author <GH_USER> --updated <from>..<to> --json number,title --limit 100`.
  For each, fetch inline comments, reviews with a body and conversation comments
  (`gh api --paginate repos/<REPO>/pulls/<N>/comments`, `.../pulls/<N>/reviews`, `.../issues/<N>/comments`).
  Keep those not written by `GH_USER`.
- **Given**: PRs reviewed by `GH_USER` in the period:
  `gh search prs --repo <REPO> --reviewed-by <GH_USER> --updated <from>..<to> --json number,title --limit 100`.
  Fetch the same three lists and keep the comments written by `GH_USER`.
- Keep only comments created in the period (`created_at`, or `submitted_at` for reviews): a PR updated in the period
  also holds older comments.
- Keep only feedback: drop replies inside a thread (inline comments with `in_reply_to_id`), so answers and "Fixed in
  ..." notes are not counted. Keep the first comment of each thread and review bodies.
- Drop bot posts that only link, summarize or advertise (`linear-code[bot]`, `github-actions[bot]` status comments,
  PR overview reviews, "comment @bot to review" tips). Tag the other bot comments as bots: every login ending in
  `[bot]`, and `Copilot`.
- A search that returns exactly 100 PRs may be truncated: say so in the report, or split the period.

Fan the per-PR fetches out in parallel (a bash helper script with `xargs -P`; zsh cannot export functions), and keep
each response in a file rather than printing it. Keep for each comment: PR, author, date, file, line, body, and the
diff hunk.

## 2. Cluster

Group comments by the underlying rule, not by wording ("use the existing helper", "test the disabled feature flag").
Keep a cluster when it appears at least twice, or once from a human and once from a bot.
For each cluster, write the rule in one sentence and keep two or three example links.

## 3. Check what already covers it

For each cluster, check whether a rule already exists in:

- the repository's review rules: `REVIEW.md`, `CLAUDE.md` files, and review skills or rule files under
  `.claude/skills/`, `.cursor/skills/` or `agents/`;
- the linter configs the repository has (ktlint, detekt, ESLint, Ruff, golangci-lint, ...);
- the user's own rules: each entry of `REVIEW_RULES`, and the user's memory files under
  `~/.claude/projects/<this project>/memory/`.

Count each rule file once: resolve symlinks (`.claude/skills` is often a link to `.cursor/skills`) and drop
`REVIEW_RULES` entries that are already in that list.

If a rule exists but the comment still came back, the rule is not working: say why (wrong scope, too vague, not
run).

## 4. Propose a destination

Pick the cheapest place that would catch it automatically, in this order:

1. **Linter rule**: mechanical and checkable. Most reliable.
2. **Team review rule**: a new or updated rule file or review skill in the repository. This is a team change: draft
   it and say it needs a PR. Offer it as an option, next to the personal one.
3. **Repository docs**: a line in `REVIEW.md` or `CLAUDE.md`. Also a team change.
4. **Personal**: a memory file (how Claude writes code for the user) and/or a bullet in the user's review rules file
   (the first file in `REVIEW_RULES`, read by `/pr-flow:pr-gate` and `ws-pr-review`). Prefer personal rules over
   team changes by default: propose a team change only as an option.
5. **Nothing**: one-off taste or already fixed upstream.

If `REVIEW_RULES` names no file, say so in the report and propose creating one, with a `.worktree-sessions` line
that points to it.

## 5. Report

Write `<REVIEWS_DIR>/<YYYY-MM>_review-feedback_draft.md`:

```
# Review feedback, <period>

<N> comments received on <P> PRs, <M> given on <Q> PRs, <K> clusters kept.

## 1. <rule in one sentence>
- Seen: <count> times (received <r>, given <g>, bots <b>). Examples: <links>
- Already covered by: <rule or "nothing">
- Proposal: <destination> — <the exact rule text or file diff>

## 2. ...

## Not kept
<one line per dropped cluster and why>
```

Then show the numbered proposals and ask which to apply ("apply 1, 3"). Personal changes can be applied right
away once chosen; team changes are drafted on a branch for a PR, never pushed without asking.
