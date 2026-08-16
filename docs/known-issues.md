# Known issues

Bounded repair loop: 4 review passes run so far.

## Resolved in pass 4 (code-review high)

All five were in the Stop hook, and together they meant the F4 guard was likelier to block a
correctly verified turn than to catch the drift it targets.

- **[HIGH]** The "current turn" boundary was wrong. `turn_start` matched any line with
  `"type":"user"`, but a real transcript wraps *tool results* in `"type":"user"` lines too, so
  the boundary landed on the last tool result rather than the last user prompt. Any tool call
  after a test run pushed the boundary past the evidence, so a genuinely verified turn got
  blocked — a regression against the pre-pass-3 whole-file scan. Verified against a real
  transcript: the old expression put the boundary at line 110 of 114 (a tool result); the fix
  puts it at line 43 (an actual prompt). Fixed by matching only user lines whose content is not
  a `tool_result`.
- **[MEDIUM]** Off-by-one: `NR>=n` included the boundary line itself, so a user prompt
  containing a build/test command name ("npm test is still failing, fix the auth logic") counted
  as tool evidence and waved an unbacked claim through. Fixed to `NR>n`; covered by
  `fixtures/user-mentions-test.json`.
- **[MEDIUM]** Fixtures used a flat one-record-per-type schema that no real transcript emits, so
  the suite passed 3/3 while the production path was broken — false confidence in exactly the
  hook whose job is catching false confidence. Rewritten against the real schema
  (`{"type":"user","message":{"role":"user","content":[{"type":"tool_result",...}]}}`), and the
  `backed` fixture now includes a trailing non-test tool call so it regresses the HIGH above.
- **[MEDIUM]** The block used the top-level `{decision, reason}` shape and exit 2, which is not
  the documented Stop shape; on a validation failure the user got a silent, unexplained block.
  Fixed to the documented `hookSpecificOutput: {hookEventName, decision, reason}` with exit 0,
  plus a top-level `systemMessage` so the reason is visible to the user either way.
- **[MEDIUM]** The hook failed *closed* on a missing or unreadable `transcript_path`, so any
  Stop payload without one blocked every turn whose final message contained "fixed" — the
  opposite of the script's own stated posture. Fixed to exit 0; covered by
  `fixtures/no-transcript.json`.
- **[MEDIUM]** `hooks.json.example` put `"matcher": "*"` on the `Stop` event, which the hooks
  docs list under "no matcher support". If the loader validates strictly the guard would be
  silently dead once copied to `hooks/hooks.json`. Matcher wrapper removed.
- **[LOW]** The test runner substituted the fixture directory with unescaped `sed` replacement
  text, so a clone path containing `&` or `|` corrupted the path and produced false failures.
  Fixed by injecting the path with `jq --arg` instead; verified by running the suite from a
  directory named `R&D|x`.
- **[LOW]** `README.md` shipped `<marketplace-name>` placeholders as install instructions for a
  marketplace this repo does not contain. Reworded to state that `--plugin-dir` is the only
  supported install path today.

Three more surfaced while reviewing the fix itself against a real transcript rather than the
fixtures:

- **[HIGH]** The evidence scan matched raw transcript lines, so the assistant *saying* "I'll run
  npm test" in prose backed its own completion claim — the model could satisfy the guard by
  naming a command it never ran. Fixed: only `tool_use` / `tool_result` lines are searched.
  Covered by `fixtures/prose-only.json`.
- **[MEDIUM]** No loop guard. The hook blocks, the model resumes, and if it still cannot produce
  evidence it stops again and is blocked again, with nothing to break the cycle. Fixed: exit 0
  when `stop_hook_active` is true, so the guard nudges once. Covered by `fixtures/reblock.json`.
- **[MEDIUM]** The runner list was narrow enough to block genuinely verified turns — this
  repo's own `check-completion-claim.test.sh` did not match it. Widened with more named runners
  plus a pattern for project-local test scripts, since a missed runner blocks correct work while
  an over-broad match only misses a bad claim.

## Resolved in pass 3

- **[HIGH]** The evidence check scanned the whole transcript for a test/build keyword, so a
  stale, unrelated test run earlier in a long session could silently back a later, untested
  completion claim. Scoped to the current turn — see the pass-4 HIGH above for the boundary
  expression that scoping originally got wrong. Covered by `fixtures/stale.json`.
- **[MEDIUM]** Fixtures hardcoded an absolute, developer-machine-specific `transcript_path`, so
  the shipped test only passed by coincidence on one machine. Fixed: the test runner now injects
  the fixture directory at run time.
- **[LOW]** Removed an unsupported claim from this file's own text ("kept intentionally per the
  project owner's decision") about `agents/openai.yaml` — no such decision was evidenced
  anywhere in the repo.

## Resolved during the loop

- **[was HIGH]** `hooks/hooks.json` shipped active and auto-registered on plugin install,
  blocking any turn with an unbacked completion claim despite being documented as "opt-in."
  Claude Code has no per-hook default-off mechanism — the only way to make a plugin-shipped hook
  genuinely inert by default is to not ship it at the exact path the loader reads
  (`hooks/hooks.json`). Fixed by shipping `hooks/hooks.json.example`; the user copies it to
  `hooks/hooks.json` to activate. Verified against the hooks docs: the loader has no filename
  fallback, so the `.example` file is confirmed inert.

## Open, low severity

- **`agents/openai.yaml`** — a pre-existing OpenAI-agent-format interface file, not a Claude
  Code subagent definition. The plugin loader only reads `.md` subagent files, so this is inert
  to Claude Code — it neither helps nor harms plugin function. Left in place for potential
  non-Claude-Code use; not a defect either way.

## Verified in this environment

- `claude --plugin-dir . -p "..."` loads the `am-i-crazy:am-i-crazy` skill and the
  `test-verifier` subagent, and `agents/openai.yaml` does not appear (matches the "inert to
  Claude Code" claim above).
- `hooks/scripts/check-completion-claim.test.sh` passes 8/8, including from a clone path
  containing shell-hostile characters (`R&D|x`).
- The hook was run end-to-end against a real `~/.claude/projects/*/*.jsonl` transcript, not only
  against fixtures: a completion claim following a genuine test run in the turn is allowed, and
  the same claim against the same transcript with the test receipts stripped is blocked.
- The block payload is valid JSON carrying
  `hookSpecificOutput.{hookEventName: "Stop", decision: "block", reason}`.

## Not verified

- **End-to-end Stop-hook registration.** Whether the hook actually fires once
  `hooks/hooks.json.example` is copied to `hooks/hooks.json` has not been observed directly —
  print-mode `--debug` surfaced no hook-registration output in this environment, and the one
  attempt to trigger it by inducing a false completion claim was refused by the model before the
  hook could fire. The matcher defect above is fixed on the strength of the docs, not of an
  observed registration. Re-verify interactively (non-`-p` mode) before relying on the hook.
- **Marketplace distribution.** This repo ships no `marketplace.json`; `--plugin-dir` is the
  only install path that has been exercised.
