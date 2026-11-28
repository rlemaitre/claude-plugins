#!/usr/bin/env bash
# Tests for plugins/kaizen/hooks/hooks.json: the classic SessionStart hook prints the rules.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$ROOT/plugins/kaizen"
failures=0
pass() { echo "ok: $1"; }
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

entry="$(jq -c '.hooks.SessionStart[0] // empty' "$PLUGIN/hooks/hooks.json")"
if [[ -z "$entry" ]]; then
  fail "hooks.json has a SessionStart hook"
else
  pass "hooks.json has a SessionStart hook"
  for event in startup resume clear compact; do
    if jq -e --arg e "$event" '.matcher | split("|") | index($e)' <<<"$entry" >/dev/null; then
      pass "SessionStart fires on $event"
    else
      fail "SessionStart fires on $event"
    fi
  done
  command="$(jq -r '.hooks[0].command' <<<"$entry")"
  out="$(cd /tmp && CLAUDE_PLUGIN_ROOT="$PLUGIN" bash -c "$command")"
  if [[ -f "$PLUGIN/rules/communication.md" && "$out" == "$(cat "$PLUGIN/rules/core.md" "$PLUGIN/rules/communication.md")" ]]; then
    pass "the hook prints rules/core.md then rules/communication.md"
  else
    fail "the hook prints rules/core.md then rules/communication.md"
  fi
  words="$(wc -w <<<"$out" | tr -d " ")"
  if (( words < 2500 )); then pass "the rules stay short ($words words)"; else fail "the rules stay short ($words words)"; fi
fi

if grep -q "prompt.context" "$PLUGIN/hooks/register.ts"; then
  fail "the mod no longer injects the rules through prompt.context"
else
  pass "the mod no longer injects the rules through prompt.context"
fi

if grep -q "Copyright (c) 2026 Ayoub Ghriss" "$PLUGIN/NOTICE.md" 2>/dev/null; then
  pass "NOTICE.md credits i-have-adhd"
else
  fail "NOTICE.md credits i-have-adhd"
fi

for heading in "## Asking" "## Simplicity" "## Enforcement" "## Work" "## Git and PRs" "## Code intelligence" "## Memory" \
  "## Documents and images"; do
  if grep -qxF "$heading" "$PLUGIN/rules/core.md"; then pass "core.md has $heading"; else fail "core.md has $heading"; fi
done

exit "$failures"
