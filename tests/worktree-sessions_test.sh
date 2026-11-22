#!/usr/bin/env bash
# Tests for plugins/worktree-sessions/bin/ws-* with fake gh, linear-cli, wt, osascript, idea and claude on PATH.
# shellcheck disable=SC2016 # the fake tools are written with single-quoted bodies on purpose
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/plugins/worktree-sessions/bin"
TMP="$(cd "$(mktemp -d)" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT
failures=0
pass() { echo "ok: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
check() { if grep -qF -- "$2" <<<"$3"; then pass "$1"; else fail "$1: no '$2' in: $3"; fi; }
check_not() { if grep -qF -- "$2" <<<"$3"; then fail "$1: '$2' found in: $3"; else pass "$1"; fi; }

# --- fake tools: each logs its arguments to $CALLS ---
FAKE="$TMP/fake"; mkdir -p "$FAKE"
fake() { printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" "%s" "$*" >> "$CALLS"\n%s\n' "$1" "${2:-}" > "$FAKE/$1"; chmod +x "$FAKE/$1"; }
fake osascript
fake idea
fake claude
fake gh 'case "$*" in
  "api user --jq .login") echo tester ;;
  "repo view --json nameWithOwner --jq .nameWithOwner") echo acme/app ;;
  "pr view 42 "*) echo "{\"number\":42,\"title\":\"Add the parser\",\"url\":\"https://github.com/acme/app/pull/42\",\"state\":\"${PR_STATE:-OPEN}\",\"headRefName\":\"feature/parser\"}" ;;
  "pr view "*) exit 1 ;;
  "pr diff 42 "*) echo "diff --git a/x b/x" ;;
esac'
fake linear-cli 'case "$*" in
  "issues get ABC-12 --output json") echo "{\"title\":\"Fix the Éclair parser\",\"url\":\"https://linear.app/acme/issue/ABC-12\",\"description\":\"The parser drops accents.\",\"state\":{\"name\":\"Todo\"},\"assignee\":${ASSIGNEE:-null}}" ;;
  "issues get "*) exit 1 ;;
  "whoami --output json") echo "{\"email\":\"me@acme.test\"}" ;;
esac'
# wt: `switch --create <branch> --no-cd` and `switch pr:<n> --no-cd` add a worktree under ../worktrees/.
fake wt 'top=$(git rev-parse --show-toplevel); case "$2" in
  --create) git worktree add -q -b "$3" "$top/../worktrees/${3//\//-}" ;;
  pr:42) git worktree add -q -b feature/parser "$top/../worktrees/feature-parser" ;;
esac'

# --- a project: config at the root, the checkout in repo/, worktrees in worktrees/ ---
new_project() {
  P="$TMP/$1"; mkdir -p "$P/remote" "$P/repo"
  git init -q --bare "$P/remote"
  git -C "$P/repo" init -q -b main
  git -C "$P/repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
  git -C "$P/repo" remote add origin "$P/remote"
  git -C "$P/repo" push -q origin main
}
run() { (cd "$P/repo" && env PATH="$FAKE:$PATH" CALLS="$TMP/calls" CLAUDE_CONFIG_DIR="$TMP/claude" "$@" 2>&1); }
TODAY="$(date +%F)"

new_project proj
cat > "$P/.worktree-sessions" <<'EOF'
# nabla-health style layout
NOTES_DIR=02_notes
BRIEFS_DIR=01_sources/briefs
REVIEWS_DIR="02_notes/reviews"
REVIEW_RULES='01_sources/review-rules.md repo/.claude/rules'
EXTRA_DIRS=01_sources
EVIL=$(touch pwned)
EOF

# ws-issue
code=0; out="$(run "$BIN/ws-issue")" || code=$?
if [[ $code -ne 0 ]]; then pass "ws-issue without an issue fails"; else fail "ws-issue without an issue: exit 0"; fi
check "ws-issue prints its usage" "usage: ws-issue" "$out"

: > "$TMP/calls"
out="$(run "$BIN/ws-issue" ABC-12)"
check "branch from the issue title, accents stripped" "tester/abc-12-fix-the-eclair-parser" "$(git -C "$P/repo" branch --list 'tester/*')"
check "assigns an unassigned issue" "linear-cli issues assign ABC-12 me" "$(cat "$TMP/calls")"
check "moves a Todo issue to In Progress" "linear-cli issues update ABC-12 --state In Progress" "$(cat "$TMP/calls")"
brief="$P/01_sources/briefs/${TODAY}_abc-12_brief.md"
if [[ -f "$brief" ]]; then pass "brief written to BRIEFS_DIR"; else fail "no brief at $brief: $out"; fi
check "brief holds the title" "# ABC-12: Fix the Éclair parser" "$(cat "$brief" 2>/dev/null)"
check "brief holds the description" "The parser drops accents." "$(cat "$brief" 2>/dev/null)"
check "brief names the plan in NOTES_DIR" "$P/02_notes/${TODAY}_abc-12-plan_draft.md" "$(cat "$brief" 2>/dev/null)"
check "prints the session command outside Ghostty" "claude --session-id" "$out"
check "session gets NOTES_DIR" "--add-dir $P/02_notes" "$out"
check "session gets EXTRA_DIRS" "--add-dir $P/01_sources" "$out"
check "session runs in auto mode" "--permission-mode auto" "$out"
check_not "does not open IntelliJ without --idea" "idea " "$(cat "$TMP/calls")"
if [[ ! -e "$P/repo/pwned" && ! -e "$P/pwned" ]]; then pass "config values are not run as shell"; else fail "config ran \$(...)"; fi

: > "$TMP/calls"
out="$(run env ASSIGNEE='{"email":"other@acme.test"}' "$BIN/ws-issue" --idea ABC-12 short name)"
check "description words make the slug" "tester/abc-12-short-name" "$(git -C "$P/repo" branch --list 'tester/*')"
check_not "leaves an issue assigned to someone else" "issues assign" "$(cat "$TMP/calls")"
check_not "does not move someone else's issue" "issues update" "$(cat "$TMP/calls")"
sleep 0.3; check "--idea opens IntelliJ on the worktree and the brief" "idea $P/worktrees/tester-abc-12-short-name $brief" "$(cat "$TMP/calls")"

: > "$TMP/calls"
out="$(run env TERM_PROGRAM=ghostty "$BIN/ws-issue" ABC-12 in ghostty)"
check "opens a Ghostty tab" "osascript - $P/worktrees/tester-abc-12-in-ghostty" "$(cat "$TMP/calls")"
check "names the tab after the issue" "[ABC-12] Fix the Éclair parser" "$(cat "$TMP/calls")"

code=0; out="$(run "$BIN/ws-issue" NOPE-1)" || code=$?
if [[ $code -ne 0 ]]; then pass "unknown issue fails"; else fail "unknown issue: exit 0"; fi
check "unknown issue is named" "Linear issue not found: NOPE-1" "$out"

# ws-pr-review
: > "$TMP/calls"
out="$(run "$BIN/ws-pr-review" https://github.com/acme/app/pull/42)"
ctx="$(git -C "$P/worktrees/feature-parser" rev-parse --absolute-git-dir)/pr-review"
check "PR URL accepted, PR worktree created" "feature/parser" "$(git -C "$P/repo" branch --list feature/parser)"
check "PR metadata saved" '"number":42' "$(cat "$ctx/pr.json" 2>/dev/null)"
check "PR diff saved" "diff --git a/x b/x" "$(cat "$ctx/pr.diff" 2>/dev/null)"
prompt="$(cat "$ctx/prompt.md" 2>/dev/null)"
check "prompt names the repository" "GitHub PR #42 of acme/app" "$prompt"
check "prompt lists the review rule files" "$P/01_sources/review-rules.md" "$prompt"
check "prompt lists the review rule folders" "$P/repo/.claude/rules" "$prompt"
check "prompt links files relative to REVIEWS_DIR" "(../../worktrees/feature-parser/<path>#L<line>)" "$prompt"
check_not "prompt has no Nabla-specific lines" "coding-backend-review" "$prompt"
check "review written to REVIEWS_DIR" "$P/02_notes/reviews/${TODAY}_pr-42_pre-review.md" "$out"
sleep 0.3; check "opens IntelliJ on the worktree" "idea $P/worktrees/feature-parser" "$(cat "$TMP/calls")"
check "runner reviews read-only" '--tools "Read,Glob,Grep"' "$(cat "$ctx/run.sh" 2>/dev/null)"
check "review skips the PR's project settings and hooks" "--setting-sources user" "$(cat "$ctx/run.sh" 2>/dev/null)"
check "review skips the PR's MCP servers" "--strict-mcp-config" "$(cat "$ctx/run.sh" 2>/dev/null)"
check "runner resumes in plan mode" "--permission-mode plan" "$(cat "$ctx/run.sh" 2>/dev/null)"
check "prints the runner outside Ghostty" "$ctx/run.sh" "$out"

code=0; out="$(run env PR_STATE=MERGED "$BIN/ws-pr-review" 42)" || code=$?
if [[ $code -ne 0 ]]; then pass "merged PR fails"; else fail "merged PR: exit 0"; fi
code=0; out="$(run "$BIN/ws-pr-review" not-a-pr)" || code=$?
if [[ $code -ne 0 ]]; then pass "bad PR argument fails"; else fail "bad PR argument: exit 0"; fi

# ws-resume: sessions are files under $CLAUDE_CONFIG_DIR/projects/<worktree path, non-alphanumerics as ->
sessions() { local d="$TMP/claude/projects/${1//[^A-Za-z0-9]/-}"; mkdir -p "$d"; for i in $(seq "$2"); do touch "$d/s$i.jsonl"; done; }
code=0; out="$(run "$BIN/ws-resume" ABC-12)" || code=$?
if [[ $code -ne 0 ]]; then pass "several worktrees without a terminal fails"; else fail "several worktrees: exit 0"; fi
check "lists the worktrees to pick from" "$P/worktrees/tester-abc-12-short-name" "$out"
code=0; out="$(run "$BIN/ws-resume" ABC-12 short-name)" || code=$?
check "a pick narrows to one worktree" "No Claude session in $P/worktrees/tester-abc-12-short-name yet" "$out"
code=0; out="$(run "$BIN/ws-resume" ABC-12 nothing-like-it)" || code=$?
check "a pick that matches nothing is named" "No worktree of ABC-12 matches nothing-like-it" "$out"
sessions "$P/worktrees/feature-parser" 2
out="$(run "$BIN/ws-resume" 42)"
check "PR with several sessions uses the picker" "claude --resume --permission-mode plan" "$out"
check "PR resume gets the review context" "--add-dir $ctx" "$out"

new_project single
git -C "$P/repo" worktree add -q -b tester/abc-12-solo "$P/worktrees/tester-abc-12-solo"
sessions "$P/worktrees/tester-abc-12-solo" 1
out="$(run "$BIN/ws-resume" abc-12)"
check "issue with one session continues it" "claude --continue --permission-mode auto" "$out"
common="$(git -C "$P/repo" rev-parse --path-format=absolute --git-common-dir)"
check "no config: notes under the git common dir" "--add-dir $common/worktree-sessions/notes" "$out"

code=0; out="$(run "$BIN/ws-resume" XYZ-9)" || code=$?
if [[ $code -ne 0 ]]; then pass "issue without a worktree fails"; else fail "issue without a worktree: exit 0"; fi
check "points to ws-issue" "No worktree for XYZ-9" "$out"

echo
if [[ $failures -eq 0 ]]; then echo "all tests passed"; else echo "$failures failure(s)"; exit 1; fi
