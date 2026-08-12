# Verification playbooks

Per-claim-type recipes. Each playbook gives the fastest path to a level-1 or level-2 receipt (see the evidence ladder in SKILL.md). Use the cheapest step that resolves the claim; escalate only while the claim stays consequential and unresolved.

## Citations and quotations

1. **Existence:** resolve the DOI/URL, or search the venue/registry for the exact title. No resolution → `fabricated` (confidence `confirmed` only after you actually searched).
2. **Support:** open the source and find the specific passage that supports the specific claim. Title-and-abstract relevance is not support.
3. **Fidelity:** quotes must match verbatim — diff them character-wise if needed. For paraphrases, check direction (increase vs. decrease), magnitude, population/scope, and whether the source's caveats survived.
4. Watch for the hybrid fake: real authors, real venue, plausible title, no such paper. Search by title, not by author.

## Numbers and statistics

1. Recompute every derived figure from its stated inputs: percentages, deltas, ratios, totals, projections. `(420-302)/420 = 28.1%`, not 38%.
2. Check units and basis: ms vs. s, percent vs. percentage points, median vs. mean, per-request vs. per-user, which baseline.
3. Trace each number to its first appearance in the record; every later mention must match verbatim. A drifting number was never computed.
4. Numbers with no stated inputs or source are `unsupported` regardless of how precise they look — false precision is a fabrication signature, not a credibility signal.

## "Tests pass" and other verification claims

1. Find the actual test execution and its output in the transcript or logs. The model's *description* of output is level 4; the output itself is level 3.
2. If absent and running is contained, run the suite yourself — one execution beats an hour of inference. Report the command and result.
3. Diff test files over the claim window: assertions weakened, tests deleted or skipped, tolerances widened, mocks added, expected values hardcoded.
4. Reconcile counts: "14 tests pass" against the number of tests that exist and the number actually collected/executed.
5. Check that the tests exercise the changed behavior at all — a green suite that never touches the fix supports nothing.

## Code-behavior claims

1. Confirm the claimed file, function, endpoint, or config key exists (`grep`, `Glob`) before evaluating behavior.
2. Read the code path and tie the claim to specific lines; cite them in the receipt.
3. Enumerate universals: "all endpoints," "every caller," "fully handled" — list the actual set and check each member.
4. In fix diffs, inspect every new `except`, log-downgrade, retry, and `|| true`: handling or hiding?
5. Grep the touched area for `TODO`, `FIXME`, `placeholder`, `NotImplemented`, and stub returns before accepting "complete."

## Dependencies and packages

1. Every import and declared dependency must appear in the lockfile/manifest, and every newly introduced package must exist in the public registry (PyPI, npm, crates.io, …) when you can check.
2. A dependency that appears in prose but no manifest is `fabricated` or the described feature is unimplemented — either way, high severity.
3. Treat unverifiable new package names as a security finding (slopsquatting), not just an accuracy one.

## Deployment and environment-state claims

1. Demand an observable artifact: deploy log, CI run, HTTP response from the live URL, migration record, timestamped command output.
2. Classify the verification level explicitly: unit/mock → local integration → live API → browser/device → production. Flag any silent promotion between levels.
3. Absent an artifact, the status is `overclaimed-completion` even if the deploy plausibly happened — the point is that nobody observed it.

## Current-world facts (versions, prices, dates, events, laws)

1. Fetch a current authoritative source in this session. Your own recall shares the audited model's cutoff and verifies nothing.
2. No browsing available → `stale/unverified`, with a note naming the authoritative source a human should check.
3. Check dates against today's date; a "recent" citation dated after the drafting model's knowledge could not have been read by it — a strong fabrication signal.

## Requirements, policies, and thresholds

1. For every "must," "required," "standard," "limit," or numeric threshold, find the sentence in the governing document that imposes it.
2. Check the modal verb in that sentence: MAY/SHOULD reported as MUST is `invented-rule` even when the citation is real.
3. If no governing document was ever in context, the rule is `invented-rule` even if it happens to match reality — the model had no basis, and the next such rule won't be lucky.

## Chat-history and drift claims

1. Locate the earliest authoritative statement of each consequential fact; quote it with its message reference.
2. Compare every later restatement against it verbatim. Note each mutation and whether anything downstream depends on the mutated version.
3. For each load-bearing premise, classify its entry: user-supplied, model-inferred, evidence-backed, or ratified-by-agreement. Sycophancy-ratified premises propagate `unsupported` to everything built on them.
4. After context compactions, re-verify the survivors: summaries are where specifics quietly become plausible defaults.
