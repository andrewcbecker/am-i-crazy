#!/usr/bin/env bash
# Stop-hook: flags completion claims ("tests pass", "fixed", "23/23", ...) in the
# assistant's final message that have no matching tool-output evidence in this
# turn's transcript. Heuristic, per docs/design.md F4 — false negatives are
# acceptable, crashing on bad input is not.
set -u

input="$(cat)"

msg="$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null)"
transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)"

# Missing/malformed input -> nothing to flag, let Stop proceed.
[ -z "$msg" ] && exit 0

completion_re='tests? (all )?pass(ed|es)?|verified|deployed|works now|\bfixed\b|all [0-9]+/[0-9]+|\b([0-9]+)/\1\b'

if ! printf '%s' "$msg" | grep -Eiq "$completion_re"; then
  exit 0
fi

# Completion language found. Look for real preceding tool-output evidence
# (a test/build/deploy command actually run) in the transcript.
evidence_re='npm (run )?test|yarn test|pnpm test|pytest|jest|go test|cargo test|rspec|mvn test|gradle test|make (test|build)|npm run build|deploy'

if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  if grep -Eiq '"type" *: *"tool_result"' "$transcript" 2>/dev/null && \
     grep -Eiq "$evidence_re" "$transcript" 2>/dev/null; then
    exit 0
  fi
fi

# Completion claim found with no matching tool-output evidence -> block.
jq -n \
  --arg ctx "The last message claims completion (e.g. \"tests pass\", \"fixed\", \"verified\", a claimed pass count) but no matching test/build/deploy tool-output was found in this turn's transcript. Verify via the test-verifier subagent or the am-i-crazy skill before finishing." \
  '{hookSpecificOutput: {hookEventName: "Stop", decision: "deny", reason: $ctx}, additionalContext: $ctx}'
exit 2
