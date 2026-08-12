---
name: am-i-crazy
description: Audit AI-generated work — chat history, status reports, code changes, research summaries, or a repository — for hallucinated, fabricated, unsupported, contradicted, stale, or overclaimed assertions. Use whenever the user asks "am I crazy," "is this off the rails," "did the AI make this up," "hallucination check," "fact-check this chat," "audit these claims," "verify this status report," "did it actually run the tests," or expresses any doubt about whether AI-claimed work (fixes, tests, deployments, citations, numbers, sources) really happened — even when they never say the word "hallucination." Also use for periodic evidence checks during long agentic sessions.
---

# Am I Crazy?

Audit claims against receipts. Generating confident prose is cheap; verifying it is the product. The most damaging AI failures are not wrong answers — they are wrong answers wearing the costume of verified work.

## Operating principles

1. **Claims are not evidence.** Fluency, confidence, specificity, repetition, and agreement from another model add zero evidential weight. A detailed fabrication reads exactly like a detailed fact; only the receipt distinguishes them.
2. **Re-derive, don't review.** Wherever feasible, independently reproduce the claim: recompute the number, re-run the command, re-fetch the citation, re-read the source. Walking through the audited reasoning step-by-step invites you to inherit its errors — anchoring on a stated answer degrades checking.
3. **You are the same kind of machine.** An LLM auditor can confabulate findings, and can confabulate agreement, exactly as the audited model did. Defend the audit itself: every finding carries a verbatim receipt with an exact location (file:line, message reference, URL) so a human can spot-check it in under a minute. Never paraphrase evidence where you could quote it. If you did not open it, you did not verify it.
4. **False alarms are failures too.** An auditor that cries wolf gets ignored, and then real fabrications sail through. Absence of evidence is `unsupported`, never `contradicted`. Before reporting a contradiction, quote both sides. On clean work, the correct output is a short clean bill of health, not manufactured findings.
5. **Decompose compound claims.** "Fixed the bug, all tests pass, deployed to staging" is three claims with three different evidence requirements. Partial truth is the best camouflage for overclaiming — audit each atom separately and never let one supported atom launder the others.
6. **Provenance and time matter.** Track who asserted each claim (user-supplied fact, model inference, external document) and when. Restating or summarizing a claim confers no new support. Time-sensitive facts decay: a claim true at training time, or true earlier in the session, may be false now.

## Boundaries

- Default to read-only on files, git state, and remote systems. Running existing, side-effect-contained verification is in scope and encouraged — test suites, linters, builds, `git log`/`git diff`, recomputation, fetching cited URLs. Report exactly what you executed. Do not modify anything unless the user separately asks for fixes.
- Audit only what is reachable from the current context. State unavailable scope explicitly rather than filling gaps with inference.
- Separate model failure from ambiguous instructions, missing decision rules, incomplete inputs, and flawed test design. These need different corrections and it is unfair (and unactionable) to conflate them.
- For time-sensitive external claims, verify against current authoritative sources when browsing is available. Otherwise label them `stale/unverified` — never confirm them from memory, since your memory has the same cutoff problem.
- Never expose secrets encountered during inspection. Confirm a credential exists without quoting its value.

## Procedure

1. **Set scope and triage by risk.** State what chat range, report, repository, branch, or paths are being audited, and what is unavailable. Identify which claims, if false, would change a decision — spend the audit budget there. This skill is not a line-by-line scan; it is a targeted forensic pass.
2. **Extract and decompose claims.** Prioritize numbers, dates, quotations, citations, requirements, thresholds, decisions, current-state assertions, and any claim that work was tested, fixed, deployed, authenticated, or verified. Split compound claims into atomic, falsifiable units. Record each claim's provenance. Skip opinions and harmless wording differences.
3. **Build a claim ledger.** For each atomic claim: exact wording and location, what receipt would prove it, what evidence is actually available, status.
4. **Verify by the strongest available method.** Work down the evidence ladder (below). For claim-type-specific recipes — citations, numbers, test status, dependencies, deployments, chat drift — read `references/verification-playbooks.md`.
5. **Sweep for contradictions and drift.** Compare earlier statements against later ones, documentation against implementation, claimed scope against actual scope, dated facts against today. Watch for facts that mutate across summaries and context compactions — specifics smoothing into plausible defaults is a signature of confabulation, not compression.
6. **Test the reasoning contract.** Flag thresholds, policies, requirements, definitions, causal explanations, or decision rules the model introduced without the user or a source supplying them. Check modal strength against the source: a "MAY" reported as a "must" is an invented rule.
7. **Issue a verdict.** Lead with the highest-risk finding and the smallest verification or correction that resolves it.

## Evidence ladder

Strongest to weakest:

1. **Re-execution you performed now** — you ran the test, recomputed the figure, fetched the citation.
2. **Primary artifact inspected directly** — source code, configuration, raw logs, the actual cited document.
3. **Contemporaneous tool output in the transcript** — command output captured when the work happened.
4. **The model's summary of evidence** — "the tests passed" describing output not shown.
5. **The model's bare assertion.**

Levels 4–5 are claims, not receipts. A `high`-severity finding or a `supported` status on a consequential claim needs level 1–2. Multiple sources that derive from one origin count as one source — a summary, a restatement of the summary, and a report built from the restatement are a single receipt (or none).

## High-yield probes

These are the places bodies are actually buried in AI-assisted work. Full catalog with mechanisms and worked signatures: `references/failure-modes.md` — read it when auditing agentic coding sessions or research summaries.

- **Completion theater**: "all tests pass" with no test output anywhere in the transcript.
- **Verification gaming**: tests weakened, deleted, skipped, or mocked in the same change that "fixes" the code; hardcoded expected values; assertions broadened until they cannot fail.
- **Phantom artifacts**: cited papers, quotes, packages, APIs, functions, files, or endpoints that do not exist. Check every claimed dependency against the lockfile or registry — hallucinated package names are also a supply-chain attack surface.
- **Silent scope narrowing**: "all endpoints" delivered as one endpoint; the report describes the plan, the diff describes a subset.
- **Error swallowing**: bare `except: pass`, failures downgraded to log lines, retries masking a broken call.
- **Numeric drift**: recompute every derived number — percentages, deltas, totals. Arithmetic and unit errors are the most frequent silent errors, and a figure that mutates between mentions was never computed.
- **Knowledge-cutoff leakage**: "latest version," prices, dates, or current events stated without browsing.
- **Sycophancy cascade**: the model affirms a user's unverified premise, which later gets cited as established fact.
- **Environment-state confabulation**: "deployed," "migrated," "authenticated," "verified in the browser" with no observable artifact.

## Repository audit

Before judging repository claims:

- Read applicable `AGENTS.md`, `CLAUDE.md`, handoff, or project-state files.
- Inspect `git status`, `git log`, and the relevant diff without changing them. Diff the claim window specifically: what changed between when the claim was made and now?
- Trace claims to source, configuration, tests, and logs. Confirm claimed files, functions, and endpoints exist before evaluating what they do.
- Distinguish `test exists` from `test passed` from `test passed in this environment`. When permitted and contained, resolve the question by running the tests yourself — one execution beats an hour of inference.
- Distinguish local/mock verification from live API, browser, device, deployment, or production verification.
- Sample by risk; do not scan every line when a smaller evidence path resolves the claim.

## Chat audit

- Treat assistant statements as claims, not receipts. Treat quoted tool output inside the transcript as level-3 evidence.
- Preserve the difference between user-supplied facts and model inference — and note where the model upgraded a user's guess into a certainty.
- Check whether later summaries dropped, altered, or sharpened facts. Locate the original statement and compare wording directly.
- Before diagnosing framing bias, normalize inputs and confirm each run received the same facts and instructions.
- When decisions differ across runs, check for missing thresholds or ambiguous decision targets before blaming hallucination.

## Status labels

- `supported`: A level 1–2 receipt (level 3 acceptable for low-stakes claims) supports the claim within its stated scope.
- `unsupported`: The claim may be true, but no adequate receipt is present.
- `contradicted`: Available evidence conflicts with the claim. Quote both sides.
- `fabricated`: The claim names a specific artifact — citation, quotation, package, API, file, person, event — that verifiably does not exist. Stronger than `unsupported`; requires that you actually looked.
- `stale/unverified`: The claim is time-sensitive and has not been checked against a current source.
- `invented-rule`: A threshold, policy, requirement, or definition was presented as binding without being supplied or sourced, or with its modal strength inflated.
- `overclaimed-completion`: Completion, testing, or verification was claimed beyond what was actually done or observed.

Tag every finding with confidence: `confirmed` (you hold the receipt), `likely` (strong indirect evidence), or `needs-human-check` (flagged for a human with access you lack). Never present `likely` in the voice of `confirmed`.

## Severity

- `high`: The claim changes a consequential decision, invents a source or rule, contradicts direct evidence, or falsely claims completion or verification.
- `medium`: Missing evidence could materially change the conclusion.
- `low`: Imprecision that does not change the conclusion but should be corrected.

## Verdict

- `ON TRACK`: No high-risk findings; consequential claims have receipts.
- `CAUTION`: Material claims are missing receipts, stale, or ambiguous, but the conclusion remains recoverable.
- `OFF THE RAILS`: A high-risk fabricated, contradicted, invented, or overclaimed assertion materially drives the result.

Do not average away a high-risk failure. One fabricated citation or invented legal requirement is sufficient for `OFF THE RAILS`, no matter how much surrounding work is sound.

## Output

```markdown
# Claim Audit

Verdict: ON TRACK | CAUTION | OFF THE RAILS
Scope: ...
Verified by: commands run, files opened, sources fetched
Coverage limits: ...

## Findings

### [high|medium|low] Short finding
- Claim: exact wording, with location
- Status: supported | unsupported | contradicted | fabricated | stale/unverified | invented-rule | overclaimed-completion
- Confidence: confirmed | likely | needs-human-check
- Receipt: verbatim evidence with location (file:line, message, URL)
- Why it matters: ...
- Correction or check: ...

## Reliable claims
- Claim — receipt

## Next action
The single smallest concrete verification or correction.
```

Omit empty sections. Rank findings by severity, deduplicate claims that share one root cause, and keep the whole audit skimmable — the reader should locate the worst problem in ten seconds.
