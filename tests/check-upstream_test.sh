#!/usr/bin/env bash
# Tests for scripts/check-upstream.sh with a fake gh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
failures=0
pass() { echo "ok: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

# Fake gh: prints $FAKE_SHA as the upstream tree hash of the plugin folder.
cat > "$TMP/gh" <<'EOF2'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_GH_CALLS"
echo "$FAKE_SHA"
EOF2
chmod +x "$TMP/gh"
run() { env GH_BIN="$TMP/gh" FAKE_GH_CALLS="$TMP/calls" "$@" "$ROOT/scripts/check-upstream.sh"; }

code=0; out="$(run FAKE_SHA=f51844eefd7eaed5e74100de794f5676683a1130 2>&1)" || code=$?
if [[ $code -eq 0 ]]; then pass "same commit: exit 0"; else fail "same commit: exit $code"; fi
if grep -q 'up to date' <<<"$out"; then pass "same commit: reported up to date"; else fail "same commit output: $out"; fi
if grep -q 'repos/anthropics/knowledge-work-plugins/contents' "$TMP/calls"; then pass "queries the upstream folder"; else fail "gh call: $(cat "$TMP/calls")"; fi

code=0; out="$(run FAKE_SHA=0123456789abcdef0123456789abcdef01234567 2>&1)" || code=$?
if [[ $code -eq 10 ]]; then pass "upstream content changed: exit 10"; else fail "upstream content changed: exit $code"; fi
if grep -q 'productivity: upstream tree 0123456, copy f51844e' <<<"$out"; then pass "names plugin and both commits"; else fail "changed output: $out"; fi

code=0; out="$(run FAKE_SHA= 2>&1)" || code=$?
if [[ $code -eq 1 ]]; then pass "empty answer from GitHub: error exit 1"; else fail "empty answer: exit $code"; fi

echo
if [[ $failures -eq 0 ]]; then echo "all tests passed"; else echo "$failures failure(s)"; exit 1; fi
