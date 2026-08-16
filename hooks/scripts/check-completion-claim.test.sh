#!/usr/bin/env bash
# Runnable self-check for check-completion-claim.sh's branching logic.
# Fixtures use the real Claude Code transcript schema (tool results arrive as
# "type":"user" lines wrapping a tool_result block) — a simplified schema here
# would pass while the production path stayed broken.
set -u
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$dir/check-completion-claim.sh"

fail=0

# want: "block" (hook returns a Stop block decision) or "ok" (hook stays quiet)
run() {
  local fixture="$1" want="$2" name="$3"
  local out got
  # jq, not sed: a fixture dir containing & or | corrupts a sed replacement.
  out="$(jq --arg d "$dir/fixtures" \
        'if .transcript_path then .transcript_path = $d + "/" + .transcript_path else . end' \
        "$dir/fixtures/$fixture" | "$script" 2>/dev/null)"
  case "$out" in
    *'"decision"'*'"block"'*) got=block ;;
    *) got=ok ;;
  esac
  if [ "$got" = "$want" ]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name (want $want, got $got)"
    fail=1
  fi
}

run backed.json            ok    "test run this turn backs the claim"
run unbacked.json          block "no test run this turn -> blocked"
run stale.json             block "test run in a prior turn does not back the claim"
run user-mentions-test.json block "user typing 'npm test' is not tool evidence"
run no-transcript.json     ok    "unreadable transcript fails open"
run no-claim.json          ok    "no completion language -> no check"
run prose-only.json        block "assistant prose naming a runner is not a receipt"
run reblock.json           ok    "stop_hook_active -> no second block (no loop)"

exit $fail
