---
name: am-i-crazy
description: Audit visible chat history, status reports, or a repository for unsupported, contradicted, stale, fabricated, or overclaimed assertions. Use when the user asks "am I crazy," "is this off the rails," "fact-check this chat," "audit these claims," "verify this status report," or wants periodic evidence checks against conversation history, source code, configuration, tests, logs, citations, or current external facts.
---

# Am I Crazy?

Audit claims against receipts. Do not treat confident prose, repeated summaries, or another model's agreement as evidence.

## Boundaries

- Operate read-only unless the user separately asks for fixes.
- Audit only history and files available in the current context. State any unavailable scope.
- Do not label a claim false merely because evidence is missing. Use `unsupported` or `unverified`.
- Separate model failure from ambiguous instructions, missing decision rules, incomplete inputs, and flawed test design.
- For time-sensitive external claims, verify with current authoritative sources when browsing is available. Otherwise label them `stale/unverified`.
- Never expose secrets encountered during repository inspection.

## Procedure

1. **Set scope.** State what chat range, report, repository, branch, or paths are being audited. Record anything unavailable.
2. **Extract consequential claims.** Prioritize numbers, dates, quotations, citations, requirements, thresholds, decisions, current-state assertions, and claims that work was tested, fixed, deployed, authenticated, or verified. Skip opinions and harmless wording differences.
3. **Build a claim ledger.** For each claim, capture its exact wording or location, required evidence, available evidence, and status.
4. **Trace receipts.** Prefer direct tool output, test output, logs, source documents, code, and configuration over summaries. Open citations and confirm they support the claim. Multiple sources derived from one origin count as one source.
5. **Check contradictions and drift.** Compare earlier and later statements, documentation against implementation, claimed scope against actual scope, and current facts against dated facts.
6. **Test the reasoning contract.** Flag thresholds, policies, definitions, causal explanations, or decision rules that were introduced by the model but not supplied or sourced.
7. **Issue a verdict.** Lead with the highest-risk result and the smallest verification or correction needed.

## Repository audit

Before judging repository claims:

- Read applicable `AGENTS.md`, handoff, or project-state files.
- Inspect `git status` and the relevant diff without changing them.
- Trace claims to source, configuration, tests, and logs.
- Distinguish `test exists` from `test passed in this environment`.
- Distinguish local/mock verification from live API, browser, device, deployment, or production verification.
- Sample by risk; do not scan every line when a smaller evidence path resolves the claim.

## Chat audit

- Treat assistant statements as claims, not receipts.
- Preserve the difference between user-supplied facts and model inference.
- Check whether later summaries dropped or altered facts.
- Before diagnosing framing bias, normalize inputs and confirm each run received the same facts and instructions.
- When decisions differ, check for missing thresholds or ambiguous decision targets before blaming hallucination.

## Status labels

- `supported`: A direct receipt supports the claim within the stated scope.
- `unsupported`: The claim may be true, but no adequate receipt is present.
- `contradicted`: Available evidence conflicts with the claim.
- `stale/unverified`: The claim is time-sensitive and has not been checked currently.
- `invented-rule`: A threshold, policy, requirement, or definition was presented without being supplied or sourced.
- `overclaimed-completion`: The response claimed completion beyond what was actually tested or observed.

## Severity

- `high`: The claim changes a consequential decision, invents a source or rule, contradicts direct evidence, or falsely claims completion.
- `medium`: Missing evidence could materially change the conclusion.
- `low`: Imprecision does not change the conclusion but should be corrected.

## Verdict

- `ON TRACK`: No high-risk findings; consequential claims have receipts.
- `CAUTION`: Material claims are missing receipts, stale, or ambiguous, but the conclusion remains recoverable.
- `OFF THE RAILS`: A high-risk invented, contradicted, fabricated, or overclaimed assertion materially drives the result.

Do not average away a high-risk failure. One fabricated citation or invented legal requirement is sufficient for `OFF THE RAILS`.

## Output

```markdown
# Claim Audit

Verdict: ON TRACK | CAUTION | OFF THE RAILS
Scope: ...
Coverage limits: ...

## Findings

### [high|medium|low] Short finding
- Claim: ...
- Status: supported | unsupported | contradicted | stale/unverified | invented-rule | overclaimed-completion
- Evidence: ...
- Why it matters: ...
- Correction or check: ...

## Reliable claims
- Claim — receipt

## Next action
One smallest concrete verification or correction.
```

Omit empty sections. Keep findings ranked and deduplicate claims that share one root cause.
