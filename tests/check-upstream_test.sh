#!/usr/bin/env bash
# Tests for scripts/check-upstream.sh with a fake gh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
failures=0
pass() { echo "ok: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# Fake gh: answers a folder query (contents API) with $FAKE_FOLDER_SHA and a repository root query
# (commits API) with $FAKE_ROOT_SHA.
cat > "$TMP/gh" <<'EOF2'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_GH_CALLS"
case "$*" in
  *"/contents/"*) echo "${FAKE_FOLDER_SHA-}" ;;
  *"/commits/HEAD"*) echo "${FAKE_ROOT_SHA-}" ;;
esac
EOF2
chmod +x "$TMP/gh"
run() { env GH_BIN="$TMP/gh" FAKE_GH_CALLS="$TMP/calls" "$@" "$ROOT/scripts/check-upstream.sh"; }

PROD=f51844eefd7eaed5e74100de794f5676683a1130
KITTY=d5cdec5eec5a0f5df6d6294579853642c1bd6ce9
OTHER=0123456789abcdef0123456789abcdef01234567

code=0; out="$(run FAKE_FOLDER_SHA=$PROD FAKE_ROOT_SHA=$KITTY 2>&1)" || code=$?
if [[ $code -eq 0 ]]; then pass "same trees: exit 0"; else fail "same trees: exit $code ($out)"; fi
if grep -q 'productivity: up to date' <<<"$out"; then pass "folder plugin reported up to date"; else fail "folder output: $out"; fi
if grep -q 'kitty-image: up to date' <<<"$out"; then pass "root plugin reported up to date"; else fail "root output: $out"; fi
if grep -q 'repos/anthropics/knowledge-work-plugins/contents' "$TMP/calls"; then pass "queries the upstream folder"; else fail "gh calls: $(cat "$TMP/calls")"; fi
if grep -q 'repos/hood/claude-kitty-image/commits/HEAD' "$TMP/calls"; then pass "queries the upstream root tree"; else fail "gh calls: $(cat "$TMP/calls")"; fi

code=0; out="$(run FAKE_FOLDER_SHA=$OTHER FAKE_ROOT_SHA=$KITTY 2>&1)" || code=$?
if [[ $code -eq 10 ]]; then pass "folder content changed: exit 10"; else fail "folder content changed: exit $code"; fi
if grep -q 'productivity: upstream tree 0123456, copy f51844e' <<<"$out"; then pass "names folder plugin and both trees"; else fail "folder changed output: $out"; fi

code=0; out="$(run FAKE_FOLDER_SHA=$PROD FAKE_ROOT_SHA=$OTHER 2>&1)" || code=$?
if [[ $code -eq 10 ]]; then pass "root content changed: exit 10"; else fail "root content changed: exit $code"; fi
if grep -q 'kitty-image: upstream tree 0123456, copy d5cdec5' <<<"$out"; then pass "names root plugin and both trees"; else fail "root changed output: $out"; fi

code=0; out="$(run FAKE_FOLDER_SHA= FAKE_ROOT_SHA=$KITTY 2>&1)" || code=$?
if [[ $code -eq 1 ]]; then pass "empty folder answer from GitHub: error exit 1"; else fail "empty folder answer: exit $code"; fi

code=0; out="$(run FAKE_FOLDER_SHA=$PROD FAKE_ROOT_SHA= 2>&1)" || code=$?
if [[ $code -eq 1 ]]; then pass "empty root answer from GitHub: error exit 1"; else fail "empty root answer: exit $code"; fi

echo
if [[ $failures -eq 0 ]]; then echo "all tests passed"; else echo "$failures failure(s)"; exit 1; fi
