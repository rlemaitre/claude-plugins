#!/usr/bin/env bash
# Tests for plugins/pr-flow/bin/pr-flow-config with a fake gh on PATH.
# shellcheck disable=SC2016 # the fake gh is written with a single-quoted body on purpose
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_BIN="$ROOT/plugins/pr-flow/bin/pr-flow-config"
TMP="$(cd "$(mktemp -d)" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT
failures=0
pass() { echo "ok: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }
check() { if grep -qxF -- "$2" <<<"$3"; then pass "$1"; else fail "$1: no line '$2' in: $3"; fi; }

mkdir -p "$TMP/fake"
cat >"$TMP/fake/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  "api user --jq .login") echo tester ;;
  "repo view --json nameWithOwner,defaultBranchRef --jq "*) printf 'acme/app\nmaster\n' ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TMP/fake/gh"

P="$TMP/proj"; mkdir -p "$P/repo/sub"
git -C "$P/repo" init -q -b master
run() { (cd "$1" && PATH="$TMP/fake:$PATH" "$CONFIG_BIN" 2>&1); }

out="$(run "$P/repo")"
common="$(git -C "$P/repo" rev-parse --path-format=absolute --git-common-dir)"
check "repository from gh" "REPO=acme/app" "$out"
check "default branch from gh" "DEFAULT_BRANCH=master" "$out"
check "GitHub user from gh" "GH_USER=tester" "$out"
check "no config: reviews under the git common dir" "REVIEWS_DIR=$common/worktree-sessions/reviews" "$out"
check "no config: no review rules" "REVIEW_RULES=" "$out"
check "no config: says so" "CONFIG=" "$out"

cat >"$P/.worktree-sessions" <<'EOF'
# shared with the worktree-sessions plugin
NOTES_DIR=02_notes
REVIEWS_DIR="02_notes/reviews"
REVIEW_RULES='01_sources/review-rules.md /abs/rules'
EVIL=$(touch pwned)
EOF
out="$(run "$P/repo/sub")"
check "config found above the checkout" "CONFIG=$P/.worktree-sessions" "$out"
check "relative reviews folder made absolute" "REVIEWS_DIR=$P/02_notes/reviews" "$out"
check "review rules made absolute, absolute kept" "REVIEW_RULES=$P/01_sources/review-rules.md /abs/rules" "$out"
if [[ ! -e "$P/pwned" && ! -e "$P/repo/sub/pwned" ]]; then pass "config values are not run as shell"; else fail "config ran \$(...)"; fi

code=0; out="$(run "$TMP")" || code=$?
if [[ $code -ne 0 ]]; then pass "outside a git checkout fails"; else fail "outside a checkout: exit 0"; fi

echo
if [[ $failures -eq 0 ]]; then echo "all tests passed"; else echo "$failures failure(s)"; exit 1; fi
