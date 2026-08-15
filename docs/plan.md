# Plan: am-i-crazy plugin build (Phase 4)

Feeds Phase 4 (implementation) of the larger workflow. Turns the approved feature set in
`docs/design.md` (F1–F7, primitive mapping: skill for F1–F3/F5–F7, `Stop` hook + `test-verifier`
subagent for F4, no MCP server) into a concrete file tree, build order, and per-file definition of
done — grounded against the currently fetched docs, not memory.

**Docs fetched today and relied on:**
- `https://code.claude.com/docs/en/plugins` ("Create plugins")
- `https://code.claude.com/docs/en/hooks` ("Hooks: Overview")
- `https://code.claude.com/docs/en/skills` ("Extend Claude with skills")
- `https://code.claude.com/docs/en/sub-agents` ("Create custom subagents")
- `https://code.claude.com/docs/en/plugin-marketplaces` ("Create and distribute a plugin
  marketplace") — fetched in this session specifically to confirm `marketplace.json`'s schema,
  which the plugins doc references but doesn't itself define.

---

## 1. File tree

```
am-i-crazy/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── am-i-crazy/
│       └── SKILL.md
├── agents/
│   ├── test-verifier.md
│   └── openai.yaml            # pre-existing, see §5 decision flag
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       └── check-completion-claim.sh
├── docs/
│   ├── research.md            # pre-existing
│   ├── design.md              # pre-existing
│   └── plan.md                # this file
├── README.md
└── LICENSE
```

A **separate, sibling repo/directory** (not inside `am-i-crazy/`) is needed only if this plugin
is distributed through a dedicated marketplace rather than installed via `--plugin-dir` or a
generic marketplace someone else hosts:

```
am-i-crazy-marketplace/            # only if the user wants a dedicated marketplace (see §5)
└── .claude-plugin/
    └── marketplace.json
```

**Note on `SKILL.md` placement:** the existing `SKILL.md` currently sits at the repo root. Per
the plugins doc, a plugin that ships exactly one skill *may* place `SKILL.md` directly at the
plugin root instead of using `skills/<name>/SKILL.md` — "Claude Code loads it as a single skill
and uses the frontmatter `name` field for the invocation name." Root placement stays valid.
This plan still recommends moving it to `skills/am-i-crazy/SKILL.md` because design.md's
primitive mapping already treats F4's Stop hook and subagent as future siblings to the skill, and
the docs explicitly say to "use the `skills/` layout for plugins that may grow to more than one
skill" — this plugin's own design doc enumerates seven features under one skill today, and the
hook/subagent split (F4) is evidence it's already grown functional edges even if the skill count
stays at one. **Flagged for the user in §5**: whether to move it or leave it at root.

---

## 2. Per-file responsibility

| File | Responsibility |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest: `name` (skill namespace — skills resolve as `/am-i-crazy:am-i-crazy` unless the SKILL.md stays at plugin root, in which case it's `/am-i-crazy` directly), `description`, `version`, optional `author`. Required for Claude Code to recognize the directory as a plugin at all; every other component loads only once this exists. |
| `skills/am-i-crazy/SKILL.md` | The claim-ledger core (F1, F2, F3, F5, F6, F7) — the existing `SKILL.md` content, moved (or left at root per §5), unchanged in substance. Its `description` frontmatter is what makes the skill auto-invocable on the audit phrasing it already documents ("am I crazy," "is this off the rails," "fact-check this chat," "audit these claims," "verify this status report"). |
| `agents/test-verifier.md` | F4's deep re-verification subagent. Frontmatter: `name: test-verifier`, `description` (triggers on "re-run tests," "verify a completion claim," used both directly and when the Stop hook flags a mismatch), `tools: Read, Bash` (per design.md's stated scope: "tool access limited to Bash + Read"), optional `model`. Body: instructions to find the actual last test-runner tool-output block or re-run the test command, and report ran/passed/failed/skipped counts distinctly from any prose claim — never trust a narrated summary. |
| `hooks/hooks.json` | Registers the `Stop` event hook per design.md's F4 automatic layer. Matcher `"*"`, command pointing at `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/check-completion-claim.sh`. This is the file that makes F4 automatic ("without anyone noticing," per research.md #4) instead of requiring `/am-i-crazy` to be typed. |
| `hooks/scripts/check-completion-claim.sh` | The Stop hook's actual logic: reads stdin JSON (`last_assistant_message`, `transcript_path`, etc. per the hooks doc's Stop-event schema), pattern-matches completion language ("tests pass," "fixed," "verified," "23/23," etc.) against whether a matching tool-output block actually appears earlier in the transcript. On a flagged mismatch, exits 2 (the only exit code that can block/continue a `Stop` event per the docs) with `continue: false` + `stopReason`, or returns `additionalContext` prompting the agent to invoke `test-verifier` before finishing. On no match, exits 0 and lets the stop proceed. |
| `README.md` | Install/usage instructions per the plugins doc's share-checklist ("Add documentation: Include a README.md with installation and usage instructions"). Not required for the plugin to function; required before público distribution. |
| `LICENSE` | Referenced by `plugin.json`'s optional `license` field if set; needed only if this is distributed publicly. Flagged in §5 — no license currently chosen. |
| `agents/openai.yaml` | Pre-existing, non-Claude-Code-plugin file (OpenAI-agent-format interface descriptor). Not part of the Claude Code plugin spec at all — `agents/` in a Claude Code plugin is reserved for subagent `.md` files with the frontmatter schema shown in the sub-agents doc, and a stray `.yaml` file there is simply ignored by the plugin loader (it only reads `.md` subagent definitions), so it does no harm sitting alongside `test-verifier.md`, but it also does nothing. Decision flagged in §5: keep, migrate, or drop. |
| `.claude-plugin/marketplace.json` (separate dir, conditional) | Only needed if distributing via a dedicated marketplace: `name`, `owner`, `plugins: [{name, source, description}]` — confirmed against the plugin-marketplaces doc's worked example. Not needed for `--plugin-dir` testing or installing through someone else's marketplace. |

---

## 3. Build order

**Phase 4 grouping — parallelizable implementation phase.**

### Group A — sequential, one person, must land first
1. `.claude-plugin/plugin.json` — nothing else can be tested (`--plugin-dir ./am-i-crazy`) without
   this existing first; it's the file that makes the directory a plugin.
2. Decide (§5, human call) whether `SKILL.md` moves to `skills/am-i-crazy/SKILL.md` or stays at
   root. This gates the actual path used in Group B, so it must be resolved before B starts, not
   during.

### Group B — parallelizable, independent files, can be built by separate agents concurrently
Once Group A's two items land, these four are independent of each other — no file reads or writes
overlaps another, and none of them depends on the others' content, only on the manifest existing:
- `skills/am-i-crazy/SKILL.md` (or root `SKILL.md`) — move/no-op the existing file to the decided
  location; content itself is already written and approved (design.md treats it as unchanged).
- `agents/test-verifier.md` — new file, depends only on plugin.json existing and the tools/model
  choice already fixed by design.md ("Bash + Read").
- `hooks/hooks.json` — new file, depends only on plugin.json existing; references a script path
  that doesn't need to exist yet for the JSON itself to be written (though it will error at hook
  invocation time until the script lands — see integration note below).
- `hooks/scripts/check-completion-claim.sh` — new file, independent of hooks.json's *content*
  (the script doesn't need to know how it's invoked to be written), but the two must agree on the
  stdin/stdout contract from the hooks doc (Stop event JSON in, exit code + optional JSON out).

### Group C — sequential integration, one person
1. Wire `hooks/hooks.json`'s `command` path to the actual `check-completion-claim.sh` path and
   confirm `${CLAUDE_PLUGIN_ROOT}` resolves (test via `claude --plugin-dir ./am-i-crazy` +
   `/reload-plugins`, per the plugins doc's local-testing flow).
2. Confirm the Stop hook, when it flags a mismatch, actually invokes/references `test-verifier`
   correctly (design.md: "Invoked either by the Stop hook ... or directly by the F4 skill logic").
   This is the one place the hook and the subagent must agree on a contract, so it can't be split
   across two people without a handoff.
3. `README.md` — written last since it documents whatever the actual invocation names and file
   locations turned out to be (namespace depends on `plugin.json`'s `name` field, decided in
   Group A).
4. `LICENSE` and `.claude-plugin/marketplace.json` — only if/after the §5 decisions are made;
   otherwise skip for a private/local-only plugin.

**Why this grouping:** Group A is the literal dependency root (docs: "the manifest file...
Claude Code uses this metadata," and every other primitive — skills, agents, hooks — loads
relative to the plugin root the manifest establishes). Group B's four files touch disjoint paths
and none is read by another during authoring, so four agents (or one agent working four times)
can write them in any order or simultaneously. Group C is sequential because it's the one place
two Group-B outputs (`hooks.json` and the script; the hook and the subagent) have to agree on an
interface neither one can verify alone — that's a single-person integration step, not a
parallelizable one.

---

## 4. Definition of done per file

| File | Done when |
|---|---|
| `.claude-plugin/plugin.json` | Valid JSON with at minimum `name` and `description` (per the docs' minimal example); `claude --plugin-dir ./am-i-crazy` starts without a manifest-parse error, and `/help` → Custom commands shows the plugin's skill under its namespace. |
| `skills/am-i-crazy/SKILL.md` (or root) | Frontmatter `description` reproduces (or closely paraphrases) the existing trigger phrasing ("am I crazy," "is this off the rails," "fact-check this chat," "audit these claims," "verify this status report") so model-invocation still fires on that language, per the skills doc: "Claude uses this to decide when to apply the skill." Body content is byte-identical or near-identical to the current `SKILL.md` — design.md treats F1–F3/F5–F7 as already correctly specified there, not something this plan rewrites. `/am-i-crazy:am-i-crazy` (or `/am-i-crazy`, depending on §5) is listed under `/help` → Custom commands and running it against a scratch chat produces the documented `# Claim Audit` output format. |
| `agents/test-verifier.md` | Frontmatter has `name: test-verifier`, a `description` an autouser/hook can match on, and `tools: Read, Bash` exactly (no broader grant — design.md is explicit this subagent's tool access is "limited to Bash + Read"). Appears under `/context` → Custom Agents once the plugin loads (per the sub-agents doc's verification step). When invoked against a repo with a stale/failing test claim, it returns a verdict that distinguishes "test exists," "test ran," and "test passed" rather than repeating the prose claim. |
| `hooks/hooks.json` | Valid JSON matching the docs' Stop-hook schema (`hooks.Stop[].matcher`, `.hooks[].type: "command"`, `.hooks[].command` using `${CLAUDE_PLUGIN_ROOT}`). Triggering a `Stop` event (ending a turn) with the plugin loaded shows the hook matched and ran in the debug log (`claude --debug`), per the plugins doc's testing guidance ("Claude Code records which hooks matched, their exit codes, and their output in the debug log"). |
| `hooks/scripts/check-completion-claim.sh` | Executable, reads the Stop-event JSON from stdin (uses `last_assistant_message` at minimum), exits `0` with no output when no completion-language pattern is found in the message, and exits `2` with a `stopReason` (or returns `additionalContext`) when it finds completion language ("tests pass," "fixed," "verified," a suspicious pass-count pattern like a claimed count higher than what appears in the transcript's actual tool-output) with no matching tool-output evidence earlier in the same turn's transcript. Verified by constructing two fixture transcripts (one with a real passing test-run tool call preceding the claim, one without) and confirming the script's exit code differs correctly between them — this is the "ONE runnable check" for this file's branching logic. |
| `README.md` | States the actual install command(s) (`--plugin-dir` and/or `/plugin marketplace add` + `/plugin install`, whichever the §5 distribution decision lands on), the actual skill invocation name, and one example of each of F1–F7 in one sentence apiece, tied to design.md's non-goals so users don't expect the out-of-scope slices (offline citations, outside-world numbers, opinion sycophancy, policy-correctness judgments). |
| `LICENSE` | Present only if §5's licensing decision resolves to "yes, license this" — done when the chosen license's canonical text is in place and `plugin.json`'s `license` field (if used) matches. |
| `.claude-plugin/marketplace.json` | Only if a dedicated marketplace is chosen (§5) — valid JSON with `name`, `owner`, and a `plugins` array entry whose `source` correctly points at the `am-i-crazy` plugin directory (relative path if colocated, git source if separate repos). Done when `/plugin marketplace add <path>` + `/plugin install am-i-crazy@<marketplace-name>` succeeds locally. |
| `agents/openai.yaml` | No action required for the plugin to function (it's inert to the Claude Code plugin loader either way) — "done" here just means the §5 keep/migrate/drop decision gets made and executed, not left ambiguous. |

---

## 5. Decisions flagged for the user

These are calls the plan cannot make on its own — a human needs to decide before or during Phase 4:

1. **Plugin/skill namespace.** `plugin.json`'s `name` field becomes the skill-invocation prefix
   (`/am-i-crazy:am-i-crazy` if `name: am-i-crazy`, or bare `/am-i-crazy` if `SKILL.md` stays at
   plugin root). Confirm the repo name `am-i-crazy` is the intended public plugin name, or pick a
   different one before writing `plugin.json`.

2. **`SKILL.md` location: move to `skills/am-i-crazy/SKILL.md`, or leave at plugin root?** Both
   are valid per the docs for a single-skill plugin. This plan recommends the `skills/` layout on
   the theory the plugin has room to grow (F4's hook/subagent split already shows functional
   growth beyond one skill file), but that's a judgment call, not a doc requirement — flag for
   confirmation, since it changes the invocation name users type.

3. **Stop hook default-on or default-off.** design.md explicitly names this tradeoff: the hook
   "runs without being asked, which cuts against the skill's 'audit only when asked' posture," and
   recommends "a clear opt-in/off switch." The docs show hooks in a plugin activate automatically
   once the plugin is enabled — there is no built-in per-hook default-off flag documented for
   plugin-shipped hooks short of the user disabling the whole plugin or using
   `disableAllHooks`/settings overrides. **Decide:** ship the Stop hook enabled by default (per
   design.md's stated rationale — it's the one feature that catches false completion claims before
   anyone asks), or document it as opt-in and require an explicit settings change to enable it. If
   opt-in is chosen, a mechanism needs specifying — this plan did not find one in the fetched docs
   for a *plugin* hook, only for user/project-level hook config, so opt-in delivery may need to be
   "documented as something the user disables via their own settings.json after installing,"
   which should be spelled out in `README.md` if chosen.

4. **Marketplace metadata (`owner`, `repository` source).** Only needed if a dedicated
   marketplace is built (§1's conditional `am-i-crazy-marketplace/`). Needs a real `owner.name`
   (and optionally a GitHub URL) — this plan cannot invent attribution. Also decide git-hosted vs.
   local-path `source` for the plugin entry.

5. **Versioning scheme.** `plugin.json`'s `version` is optional; if omitted, the docs describe a
   fallback chain (not fully explored in this fetch — see "version management" in the plugins
   reference, which the plugins doc links but this plan did not separately fetch). Decide whether
   to start at `0.1.0`/`1.0.0` and whether semver bumps are manual.

6. **License.** No `LICENSE` file exists today and design.md doesn't address one. Decide whether
   this is a private/personal plugin (no license needed) or intended for the community marketplace
   (a license is effectively required for review/distribution per the plugins doc's "Share your
   plugins" checklist).

7. **`agents/openai.yaml` — keep, migrate, or drop?** It's a pre-existing OpenAI-agent-format
   interface file (`display_name`, `short_description`, `default_prompt`), not a Claude Code
   subagent definition, and the plugin loader ignores it. Now that this is explicitly becoming a
   Claude Code plugin (not a cross-platform agent spec), decide whether to (a) delete it as
   dead weight, (b) keep it uncounted alongside `test-verifier.md` for some other non-Claude-Code
   consumer, or (c) migrate its `display_name`/`short_description`/`default_prompt` content into
   `plugin.json`'s `description` and `README.md` and then delete it. This plan did not find any
   Claude Code plugin mechanism that reads this file, so leaving it in place is inert but not
   harmful — purely a repo-hygiene call.

8. **Distribution channel.** Local-only (`--plugin-dir`), a dedicated marketplace repo, or
   submission to the community marketplace (`claude-community`)? This determines whether
   `README.md`, `LICENSE`, and `marketplace.json` are needed at all for v1, or deferred.

---

## 6. Assumptions not fully confirmed against the fetched docs

- **`test-verifier.md`'s exact frontmatter beyond `name`/`description`/`tools`** (e.g. whether a
  `model` override is needed) — design.md doesn't specify a model, and this plan defaults to
  omitting the field (inherits session model) rather than guessing a value. Flag if a specific
  model (e.g. a cheaper/faster one for the re-verification pass) is wanted.
- **Version-management fallback chain** referenced by the plugins doc ("If omitted, the version
  comes from the next source in version management") was not separately fetched from
  `/docs/en/plugins-reference` — §5 decision 5 notes this gap explicitly rather than assuming a
  default.
- **Whether a plugin-shipped hook supports a documented per-hook opt-out** (§5 decision 3) — not
  found in the fetched hooks doc; flagged rather than asserted.
