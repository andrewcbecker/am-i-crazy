# Design: am-i-crazy plugin

Feature set for the `am-i-crazy` Claude Code plugin, built on the existing claim-audit
discipline in `SKILL.md` (evidence over confidence, read-only by default, `unsupported` ≠
`false`, severity-ranked findings, ON TRACK / CAUTION / OFF THE RAILS verdict) and scoped by
the detectability findings in `docs/research.md`.

Sources read for primitive grounding (fetched today via WebFetch):
- `https://code.claude.com/docs/en/plugins` ("Create plugins")
- `https://code.claude.com/docs/en/hooks` ("Hooks: Overview")
- `https://code.claude.com/docs/en/skills` ("Extend Claude with skills")
- `https://code.claude.com/docs/en/sub-agents` ("Create custom subagents")

**Correction to a prior assumption:** I expected "slash command" to be a distinct plugin
primitive alongside skills. The docs say otherwise: *"Custom commands have been merged into
skills. A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md`
both create `/deploy` and work the same way."* A skill is invoked either automatically
(model-invoked, based on its `description`) or explicitly via `/name`, controlled by the
`disable-model-invocation` frontmatter flag. So "skill" and "slash command" below are the same
primitive, distinguished only by that flag — there is no separate command primitive to reach
for.

---

## 1. Proposed features (mapped to failure modes)

### F1 — Receipt-trace a citation
**Failure mode:** #1 Fabricated citations (**partial** — eligible slice only: URL/file
citations, not offline sources).
**What it does:** For every citation in scope that is a URL or a file/line reference, open it
(WebFetch for URLs, Read for files) and confirm (a) it resolves/exists and (b) it actually
supports the specific claim attached to it. Citations that are not reachable by any available
tool (a physical book, a private API response never captured in the transcript) are labeled
`unsupported`, never `contradicted` or `false` — the plugin has no way to prove a negative on an
unreachable source.

### F2 — Recompute stated numbers from source
**Failure mode:** #2 Confident wrong numbers (**partial** — eligible slice: numbers about the
repo/session; outside-world numbers only when a live tool call can reach an authoritative
source, in which case treat them as F3).
**What it does:** Every stated count, date, or measurement about the codebase or the visible
conversation (line counts, file counts, test counts, commit dates) gets recomputed directly
(`grep -c`, `git log`, `wc -l`, re-reading the file) rather than trusted from prose.

### F3 — Flag unrefreshed time-sensitive claims
**Failure mode:** #3 Stale facts presented as current (**partial** — eligible slice: claims
where a version-check command or WebFetch against current docs is actually available in the
session; not claims about vendor-internal/unbrowsable state).
**What it does:** Any prose assertion of the form "the current version/price/API is X" gets
checked against a live source if one is reachable (`pip show`, `npm view`, `WebFetch` on the
vendor's current docs). If no live check is reachable in this session, label `stale/unverified`
— never assert correctness by default.

### F4 — Verify claimed-but-untested work
**Failure mode:** #4 Claimed-but-untested work (**yes** — strongest, most directly actionable
case per research.md).
**What it does:** Distinguishes "a test exists in the repo," "a test was run in this session,"
and "a test passed," by finding the actual last tool-output block for the relevant command
(not the prose summary that followed it) or re-running the command. Also catches the "23/23"
pattern — a claimed pass count higher than what the actual run reported.

### F5 — Diff earlier vs. later statements in-session
**Failure mode:** #5 Silent drift across a long session (**yes**, when both statements are
present in visible history; becomes unrecoverable — and is reported as such, not guessed — if
the earlier statement was truncated/summarized out of context).
**What it does:** Compares an early decision or fact against how a later summary in the same
session restates it, and flags softening, dropping, or contradiction.

### F6 — Check user premises about the repo
**Failure mode:** #6 Sycophantic agreement (**partial** — eligible slice only: a user's factual
claim about the codebase/config/tool-observable state that the agent accepted and built on
without checking; NOT the user's opinions, private situation, or claims about the outside
world).
**What it does:** When the transcript shows the agent agreeing with a stated premise like "this
function already handles nulls," the plugin checks that premise against source directly. If the
premise is about anything outside repo/tool-observable state, the finding is capped at "user
premise stated as fact, not independently verified" — no true/false adjudication attempted.

### F7 — Source-check invented thresholds/policies
**Failure mode:** #7 Invented thresholds/policies (**yes**, for "was this ever supplied or
sourced" — **not** for "is this threshold actually correct/wise").
**What it does:** Any stated rule, numeric threshold, or definition gets searched against every
file, config, and prior user message in scope. If nothing in scope supplies it, it's labeled
`invented-rule` regardless of how authoritative the phrasing sounds. The plugin never opines on
whether an unsourced rule happens to be good policy — only that it's unsourced.

---

## 2. Explicit non-goals

- **Adjudicating offline citations** (#1's undetectable slice). A citation to a physical book or
  an unreachable private source stays `unsupported` forever — the plugin will not guess.
- **Confirming outside-world numbers with no live source reachable** (#2's undetectable slice —
  market stats, populations, prices with browsing off or the source unbrowsable). Labeled
  `unsupported`/`stale/unverified`, not silently trusted or silently rejected.
- **Confirming staleness for vendor-internal/private facts** (#3's undetectable slice) — no tool
  call can reach these; the plugin will not simulate a live check it can't perform.
- **Recovering drift from truncated history** (#5's undetectable edge). If the earlier statement
  isn't anywhere in context, the plugin reports "earlier scope not in context," not a guess at
  what was said.
- **Adjudicating sycophancy on opinions or outside-world claims** (#6's undetectable slice) —
  research.md is explicit that the auditing agent has no more ground truth here than the
  original model did. Out of scope entirely; not even attempted at reduced confidence.
- **Judging whether an invented threshold is actually good policy** (#7's undetectable slice) —
  the plugin proves absence of a source, never correctness or wisdom of a rule.
- **Generation-time hallucination prevention** (RAG groundedness scoring, citation-graph
  verification at write time). This plugin audits *after the fact*, in an existing session or
  repo; it is not a drop-in replacement for domain fact-checking infrastructure (Westlaw/Lexis,
  a vetted document corpus) and does not claim to be one.
- **Automatic fixing.** Per SKILL.md, read-only by default. The plugin proposes the smallest
  verification/correction; it does not silently patch code, rewrite claims, or auto-file
  corrections unless the user separately asks for fixes.
- **A general sycophancy or alignment fix.** Not attempting to change model behavior — only to
  audit its output against available receipts.

---

## 3. Primitive mapping

| Feature | Primitive | Why this primitive, per the docs |
|---|---|---|
| F1–F3, F5–F7 (the claim-ledger core) | **Skill** (extends existing `SKILL.md`, invoked as `/am-i-crazy` or auto-invoked when description matches) | Docs: a skill is "model-invoked... based on the task context" or explicitly run via `/name`; it can inject live context with the `` !`command` `` syntax before Claude ever sees the instructions (e.g. `` !`git diff HEAD` ``). This is exactly the claim-ledger's need — pull real evidence (grep output, git log, file contents) into context rather than trust prose — and it needs user judgment/multi-step reasoning across arbitrary evidence, which is what a skill's instruction body is for. A hook cannot do this: hooks run a fixed script/prompt against one lifecycle event, not an open-ended investigation across whatever the user asks to audit. |
| F4 — completion-claim guard (automatic layer) | **Hook**, `Stop` event (fires once per turn, per the docs' cadence table) | This is the one feature where *automatic, no-invocation* interception matters: research.md calls #4 the failure the plugin can catch "without anyone noticing," i.e., before the user even asks for an audit. Docs confirm hooks "fire automatically... no manual invocation required," and `Stop` fires once per turn — the natural point to check whether the agent's outgoing message contains completion language ("tests pass," "fixed," "verified") unmatched by an actual test-runner tool call earlier in the same turn. On mismatch, the hook returns `additionalContext` (or blocks via exit code `2`, per the docs' "Block Actions" section) forcing the agent to correct the claim before it reaches the user. A skill can't do this — it only runs when invoked, and by the time someone thinks to invoke `/am-i-crazy` the false "tests pass" claim has often already shipped. |
| F4 — deep re-verification | **Subagent** (`test-verifier`, tool access limited to Bash + Read) | Docs: subagents run in "its own context window with a custom system prompt, specific tool access, and independent permissions," and exist to "preserve context by keeping exploration... out of your main conversation." Actually re-running a test suite and interpreting nuanced output (skipped vs. failed vs. errored, flaky vs. deterministic) needs an LLM with tool access, not just a shell script — so a hook alone can't do the interpretation, only detect the *absence* of a check. The subagent does the heavier lifting in an isolated context so re-running tests doesn't flood the main audit thread, and returns only the verdict. Invoked either by the `Stop` hook (when it finds a completion claim with no matching evidence) or directly by the F4 skill logic on `/am-i-crazy`. |
| Everything else | **No MCP server, no plugin-level LSP/monitor** | The docs list MCP servers for "external tool integration" — but every feature here resolves against tools already built into Claude Code (Read, Grep, Bash, WebFetch, git). Adding an MCP server would mean standing up and maintaining an external service for zero net new capability; the ladder favors the already-available primitive. |

---

## 4. Tradeoffs

**F1 (citation receipt-trace) — skill.**
Gives up: coverage. Only catches citations phrased as URLs/files; anything else is
`unsupported` by design, which can read as "the plugin missed it" if the user expects a verdict.
Requires the user (or the model) to invoke the audit — no automatic net.

**F2 (recompute numbers) — skill.**
Gives up: doesn't scale to every number in a long report; SKILL.md already says "sample by
risk," so low-stakes imprecise numbers may not get individually recomputed. False-negative risk
on numbers phrased so vaguely they don't register as "consequential."

**F3 (stale-claim flag) — skill.**
Gives up: depends entirely on whether a live-check tool is actually reachable in the session
(WebFetch enabled, package registry reachable). In a fully offline session this feature degrades
to "everything time-sensitive is `stale/unverified`," which is correct but low-value output if
overused — real risk of alert fatigue if every time-sensitive sentence gets flagged.

**F4 completion-claim guard — hook (`Stop`).**
Gives up: performance/latency cost on every turn (a hook runs on every `Stop` event, not just
ones with completion claims — cost is paid even on turns where nothing needs checking).
Invasiveness: this is the one feature that runs without being asked, which cuts against the
skill's "audit only when asked" posture in SKILL.md — needs a clear opt-in/off switch
(`disableAllHooks` or plugin settings) so it doesn't become an unwanted always-on nag.
False-negative risk: text pattern matching for "completion language" is heuristic; a claim
phrased unusually ("should be good now") can slip past the matcher.

**F4 deep re-verification — subagent.**
Gives up: cost and time — spinning up a subagent to re-run a full test suite is far more
expensive than the hook's lightweight text check, so it should only trigger on a hook-flagged
mismatch, not on every turn. Also inherits whatever the test suite's own blind spots are (F4
proves "ran and passed," not "the feature actually works for the user," which research.md
separately notes as a distinct, harder problem — local/mock vs. live verification, called out in
SKILL.md's repo-audit section).

**F5 (drift diff) — skill.**
Gives up: entirely dependent on context still holding the earlier statement; in practice, long
sessions that got compacted or summarized will silently lose exactly the material this feature
needs, and the plugin can only report the gap, not fill it.

**F6 (premise check) — skill.**
Gives up: narrow by design — most of what people mean by "sycophancy" (agreement on opinions,
non-repo facts) is explicitly out of scope, so this feature will read as incomplete to anyone
expecting a general sycophancy detector. That narrowness is the point (research.md marks the
rest undetectable), but it needs to be stated plainly in output, not just implied.

**F7 (invented-rule source-check) — skill.**
Gives up: a rule can be technically "sourced" (present in some file) while still being cherry-
picked, outdated, or misapplied to this claim — the check only proves presence somewhere in
scope, not that the source actually supports this specific use. Requires the user to trust that
"has a source" and "correctly used" aren't being conflated in the output.

**Cross-cutting: relying on a hook at all.**
Every hook the docs describe is scoped to *this session's* tool calls and lifecycle events — it
cannot see or protect anything outside the current Claude Code session (a claim made in a
different tool, a different agent, a human-written report). The hook layer only ever covers the
"claimed-but-untested work happening right now, in this session" slice — it is not a substitute
for the on-demand skill's broader audit of history/files/repo already in scope.
