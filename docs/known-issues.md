# Known issues

Bounded repair loop: 2 review passes run, exited at condition (a) — pass 2 returned no
findings at `high` or `medium` severity.

## Resolved during the loop

- **[was HIGH]** `hooks/hooks.json` shipped active and auto-registered on plugin install,
  hard-blocking any turn with an unbacked completion claim (exit 2 = unconditional Stop block
  per the docs), despite being documented as "opt-in." Claude Code has no per-hook default-off
  mechanism — the only way to make a plugin-shipped hook genuinely inert by default is to not
  ship it at the exact path the loader reads (`hooks/hooks.json`). Fixed by shipping
  `hooks/hooks.json.example` instead; the user copies it to `hooks/hooks.json` to activate.
  Verified against a fresh fetch of the hooks docs in the second review pass: the loader has no
  filename fallback, so the `.example` file is confirmed inert.

## Open, low severity

- **`agents/openai.yaml`** — a pre-existing OpenAI-agent-format interface file, not a Claude
  Code subagent definition. The plugin loader only reads `.md` subagent files, so this is inert
  to Claude Code — it neither helps nor harms plugin function. Kept intentionally per the
  project owner's decision (for potential non-Claude-Code use), not a defect.

## Deferred (not evaluated this pass)

- **Live dynamic install test** (`claude --plugin-dir ... -p "..."`) was not run in either
  review pass — one hit a sandbox restriction on nested `claude` invocations, the other had no
  `claude` binary available at all. Both passes fell back to static validation (manifest JSON
  validity, exact directory paths matching the fetched docs' conventions) and said so
  explicitly rather than silently skipping the check. A real interactive install/list-skills
  check is still worth doing outside this environment before wide distribution.
- **Marketplace remote correctness** — `am-i-crazy-marketplace/.claude-plugin/marketplace.json`
  points at `github:andrewcbecker/am-i-crazy`. That remote didn't exist as a real GitHub repo
  path verifiable from this sandbox; it will need to actually exist (i.e. this local repo
  pushed there) before anyone else can `/plugin marketplace add` it.
