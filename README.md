# am-i-crazy

A Claude Code plugin that audits AI output — chat history, status reports, or a
repository — against actual receipts instead of confident prose. Catches unsupported,
contradicted, stale, fabricated, or overclaimed assertions.

Evidence over confidence. Read-only by default. `unsupported` is never treated as `false`.

## Install

```
claude --plugin-dir /path/to/am-i-crazy
```

Or, once published to a marketplace:

```
/plugin marketplace add <marketplace-name>
/plugin install am-i-crazy@<marketplace-name>
```

## What it does

| Feature | Failure mode it catches | How |
|---|---|---|
| Receipt-trace a citation | Fabricated citations | Opens every URL/file citation and confirms it exists and supports the claim. |
| Recompute stated numbers | Confident wrong numbers | Re-derives counts/dates/measurements from the repo or transcript directly. |
| Flag unrefreshed claims | Stale facts presented as current | Checks time-sensitive claims against a live source when one is reachable; otherwise labels `stale/unverified`. |
| Verify claimed-but-untested work | Overclaimed completion | Distinguishes "test exists" / "test ran" / "test passed" by finding the real tool-output, not the prose summary. |
| Diff earlier vs. later statements | Silent drift | Flags a later summary that softened, dropped, or contradicted an earlier in-session statement. |
| Check user premises | Sycophantic agreement | Verifies a user's factual claim about the repo/config before the model builds on it — never adjudicates opinions or outside-world claims. |
| Source-check thresholds | Invented rules/policies | Confirms a stated rule or threshold was actually supplied somewhere in scope. |

Run the skill directly: `/am-i-crazy` (or via chat: "am I crazy", "audit these claims",
"is this off the rails", "fact-check this chat", "verify this status report").

## Non-goals

This plugin does not, and will not attempt to:
- Adjudicate offline citations (a physical book, an unreachable private source) — labeled `unsupported`, never guessed.
- Confirm outside-world facts with no live source reachable in the session.
- Recover drift from conversation history that's already been truncated or summarized out of context.
- Judge sycophancy on opinions or claims about the outside world, only on repo/tool-observable facts.
- Judge whether an invented threshold is good policy — only whether it was ever sourced.
- Prevent hallucination at generation time (it audits after the fact).
- Auto-fix anything. It proposes the smallest verification or correction; you make the change.

See `docs/research.md` and `docs/design.md` for the full reasoning behind each boundary.

## The Stop hook (completion-claim guard)

The plugin ships a `Stop`-event hook (`hooks/scripts/check-completion-claim.sh`) that can
automatically flag a turn ending with an unbacked completion claim ("tests pass", "fixed",
"23/23") — catching the single most common and most detectable failure mode (overclaimed
completion) without anyone having to remember to run `/am-i-crazy`.

**This hook is opt-in.** Claude Code's plugin hook system has no per-hook disable flag — any
`hooks/hooks.json` a plugin ships activates automatically the moment the plugin loads, with no
"installed but off" state. Because of that, this hook is **not** registered in the plugin's
default `hooks/hooks.json` path. Instead it ships as `hooks/hooks.json.example` — inert until you
turn it on yourself:

```
cp hooks/hooks.json.example hooks/hooks.json
```

(then reload the plugin, e.g. `/reload-plugins` in a running session, or restart with
`--plugin-dir` pointed at this directory).

To turn it back off, delete or rename `hooks/hooks.json` again — there is no separate settings
flag needed since the plugin only registers the hook when that exact file is present.

If you never create `hooks/hooks.json`, the Stop hook never runs — you get only the on-demand
`/am-i-crazy` skill and the `test-verifier` subagent (invocable directly), matching the plugin's
default "audit only when asked" posture.

## Subagent: test-verifier

`agents/test-verifier.md` re-runs or re-checks a claimed test/build result directly (tool
access limited to `Read` + `Bash`). It's invoked either by the Stop hook when it flags a
completion claim with no backing evidence, or directly when you ask for a deeper check than the
hook's pattern match can give.

## Development

Run the hook script's fixture self-check after any change to
`hooks/scripts/check-completion-claim.sh`:

```
hooks/scripts/check-completion-claim.test.sh
```

## Design docs

- `docs/research.md` — documented failure modes, sources, and detectability verdicts.
- `docs/design.md` — feature set, non-goals, primitive choices, and tradeoffs.
- `docs/plan.md` — file tree, build order, and per-file definition of done.

## License

MIT — see `LICENSE`.
