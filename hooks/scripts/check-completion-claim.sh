#!/usr/bin/env bash
# Stop-hook: flags completion claims ("tests pass", "fixed", "23/23", ...) in the
# assistant's final message that have no matching tool-output evidence in this
# turn's transcript. Heuristic, per docs/design.md F4 — false negatives are
# acceptable, blocking a turn we could not actually assess is not.
set -u

input="$(cat)"

msg="$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null)"
transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)"

# Missing/malformed input -> nothing to flag, let Stop proceed.
[ -z "$msg" ] && exit 0

# Already resumed once by this hook: block again and the turn can never end.
# One nudge is the whole point; a loop is just a hang.
if [ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ]; then
  exit 0
fi

completion_re='tests? (all )?pass(ed|es)?|verified|deployed|works now|\bfixed\b|all [0-9]+/[0-9]+|\b([0-9]+)/\1\b'

if ! printf '%s' "$msg" | grep -Eiq "$completion_re"; then
  exit 0
fi

# No readable transcript -> no evidence either way. Fail open.
if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

# Completion language found. Look for real preceding tool-output evidence
# (a test/build/deploy command actually run) in the transcript.
# Wide on purpose: a missed runner blocks a turn that really was verified, which
# is the costlier direction. The trailing pattern catches project-local runners
# (./run-tests.sh, foo.test.sh, test_thing.py) the named list can't enumerate.
evidence_re='npm (run )?test|yarn test|pnpm test|pytest|jest|vitest|go test|cargo test|rspec|mvn test|gradle test|make (test|build)|npm run build|ctest|tox|bats|phpunit|dotnet test|swift test|deploy|[^ "]*test[^ "]*\.(sh|bash|py|js|ts|rb)'

# Scope evidence to the current turn: everything after the last real user
# prompt. Tool results are also "type":"user" lines in a real transcript, so a
# prompt is a user line whose content is not a tool_result — matching bare
# "type":"user" would put the boundary on the last tool result instead.
turn_start="$(jq -r '
  select(.type == "user"
    and ((.message.content | type) == "string"
         or ([.message.content[]?.type] | index("tool_result") | not)))
  | input_line_number' "$transcript" 2>/dev/null | tail -1)"
turn_start="${turn_start:-0}"

# NR>n, not NR>=n: the boundary line is the user's own prompt, and the user
# typing "npm test is still failing" is not tool evidence.
turn="$(awk -v n="$turn_start" 'NR>n' "$transcript" 2>/dev/null)"

# Only tool_use/tool_result lines count. The assistant *saying* "npm test" in
# prose is the claim, not the receipt — matching raw lines would let the model
# back its own claim by mentioning a command it never ran.
# ponytail: line-level filter, so prose sharing a line with a tool_use still
# counts; parse content blocks with jq if that ever matters.
tool_lines="$(printf '%s' "$turn" | grep -E '"type" *: *"tool_(use|result)"')"

if printf '%s' "$tool_lines" | grep -Eq '"type" *: *"tool_result"' && \
   printf '%s' "$tool_lines" | grep -Eiq "$evidence_re"; then
  exit 0
fi

# Completion claim with no matching tool-output evidence -> block the Stop.
reason="The last message claims completion (e.g. \"tests pass\", \"fixed\", \"verified\", a claimed pass count) but no matching test/build/deploy tool-output was found in this turn's transcript. Verify via the test-verifier subagent or the am-i-crazy skill before finishing."

jq -n --arg reason "$reason" '{
  systemMessage: $reason,
  hookSpecificOutput: {
    hookEventName: "Stop",
    decision: "block",
    reason: $reason
  }
}'
exit 0
