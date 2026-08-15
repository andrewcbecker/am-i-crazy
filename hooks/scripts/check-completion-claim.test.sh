#!/usr/bin/env bash
# Runnable self-check for check-completion-claim.sh's branching logic.
set -u
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$dir/check-completion-claim.sh"

pass=0

run() {
  local fixture="$1" want="$2" name="$3"
  local got
  "$script" < "$fixture" > /dev/null 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then
    echo "PASS: $name (exit $got)"
  else
    echo "FAIL: $name (want exit $want, got $got)"
    pass=1
  fi
}

run "$dir/fixtures/backed.json" 0 "backed claim -> exit 0"
run "$dir/fixtures/unbacked.json" 2 "unbacked claim -> exit 2"

exit $pass
