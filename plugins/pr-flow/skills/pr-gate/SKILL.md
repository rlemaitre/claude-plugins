---
name: pr-gate
description: Run the pre-PR gate on the current branch - structure commits, team review, fresh-agent review, fixes, comprehension check, then open the PR. Use only when the user types /pr-gate.
disable-model-invocation: true
---

# Pre-PR gate

One command between "the code works" and "the PR is open", so nothing depends on remembering a step.
The order is fixed: structure, review, fix, check comprehension, open. Stop at any step that fails and say why.

`gh` needs the network: when a `gh` or `pr-flow-config` call fails with a TLS or certificate error, the sandbox
blocked it; run it again outside the sandbox.

## 0. Resolve the branch and base

1. Run `pr-flow-config` (bare name, on its own) for `DEFAULT_BRANCH` and `REVIEW_RULES`.
2. Refuse to run on `DEFAULT_BRANCH`.
3. Uncommitted changes: list them and ask whether to commit them first. Never stash or discard them.
4. Base: the base of the open PR if one exists (`gh pr view --json baseRefName,isDraft,reviews`), otherwise the
   parent branch for a gh-stack branch (`gh stack view`), otherwise `DEFAULT_BRANCH`. Then `git fetch origin <base>`.
5. If a PR already exists and has reviews, the branch is under review: do not rewrite history in any step
   (no rebase, no reset, no amend; add commits instead). Say so up front.
6. Build check: find the commands that compile the code and its tests in the repository's `CLAUDE.md` (or its
   README or build files). Later steps run them for the touched modules. Say which command you will use.

## 1. Structure the commits

Skip this step when the branch is under review (step 0.5). If the repository has a skill for structuring commits,
follow it on `origin/<base>...HEAD`. Otherwise:

- Separate mechanical changes (renames, moves, formatting, generated code, dependency bumps) from the changes that
  alter behavior, so a reviewer can skim the first and read the second.
- Put refactors that keep behavior before the change that needs them; keep tests in the commit of the code they test.
- One concern per commit, with a message in the repository's style that says why.

Every commit must compile on its own: after restructuring, run the build check on each new commit
(`git rebase --exec` is fine before review). Report a commit that fails and stop.

## 2. Review, in parallel

Run both reviews in one parallel batch. Both are read-only.

- **Team review**: for each review skill in the repository (`.claude/skills/*review*/SKILL.md` or the same under
  `.cursor/skills/`) whose scope covers files in the diff, read it and follow it against `<base>`, in report-only mode:
  never post comments. Keep each merged report. Say so when the repository has none.
- **Fresh-agent review**: spawn one general-purpose subagent that knows nothing about this work. Give it only the
  base, the repository root, and this brief: "Review the full diff `git diff origin/<base>...HEAD` for
  correctness bugs, missed edge cases, broken contracts, missing tests and unneeded complexity (name the simpler
  form). Read surrounding code to confirm each finding. Report each as `file:line`, severity (high/medium/low), what
  is wrong, and the fix. Report nothing you could not confirm." When `REVIEW_RULES` is not empty, add: "Also check
  every rule in: <each entry of REVIEW_RULES> (files, or folders of rule files)."

## 3. Merge and ask

Merge the reports into one list, numbered `#1` to `#N`, most severe first. Deduplicate findings on the same
`file:line` and keep both sources. Show the list and ask which to fix ("fix 1-3, skip 4").
Numbers stay fixed for the rest of the conversation.

## 4. Fix

- Fix the chosen findings with the simplest change that fixes the cause: never disable a lint rule, suppress a
  warning or skip a test to pass.
- Commit the fixes in commits that each compile, structured as in step 1. Under review: new commits only.
- Run the tests of the touched modules. If a test fails for a reason unrelated to the branch, say which and
  continue; do not fix it here.
- Any `high` finding left unfixed blocks the PR unless the user says to go ahead.

## 5. Check comprehension

Check that the user understands what the branch does before it goes to reviewers. Practice, not proof of authorship.

1. Size the diff (`git diff --stat origin/<base>...HEAD`, ignoring tests, generated code and docs):
   docs-only or under ~30 changed lines: skip this step and say so; up to ~300 lines: 2 questions; more: 3.
2. Spawn one general-purpose subagent, the examiner. It knows nothing about this work: give it only the base, the
   repository root, the question count and this brief: "You test a developer's understanding of
   `git diff origin/<base>...HEAD`. Read the diff and the surrounding code. Write <N> open questions about
   behavior, failure modes, invariants or why a design choice was made: what happens when X, what breaks if Y.
   Never ask trivia (names, file locations, syntax). Each question is one concept and answerable in 2-3 sentences
   without opening the code. For each, write a private acceptance: the expected prediction, the causal reason, and
   the `file:line` evidence. Return the questions and the acceptances in separate sections."
3. Show the user only the questions, numbered `Q1` to `QN`. Never show or paraphrase the acceptances, and give no
   hints. The user answers in one message.
4. Send the answers to the same examiner (`SendMessage`) to grade: each answer is `correct`, `incorrect` or
   `ambiguous` against its acceptance; the right idea in different words is `correct`. For each non-correct answer
   it returns a short explanation with the evidence and one new question on the same concept, with a new acceptance.
5. Show the grades and explanations, then ask the new questions. Repeat 4-5 until every concept is `correct`.
6. The user may say "skip comprehension": stop asking, and report it as skipped in step 6. Nothing else skips it.

## 6. Open the PR

If the repository has a skill for opening PRs, follow it. Otherwise open a draft PR with `gh pr create --draft`,
following the user's PR instructions (assignee, description) from their CLAUDE.md, with a description that covers
the whole branch diff and a test plan. For a gh-stack branch, push with `gh stack push` instead of `git push`. If the
PR already exists, push the new commits and stop.

End with: the PR URL, the findings fixed and skipped by number, the comprehension result (passed, skipped or not
needed), and the suggestion to run `/loop /pr-flow:pr-babysit`.

## Never

- Force-push, or rewrite a branch under review.
- Post review comments or replies on GitHub.
- Mark the PR ready for review or merge it.
- Show or hint at the examiner's acceptances before the user answers, or answer a comprehension question in the
  user's place.
