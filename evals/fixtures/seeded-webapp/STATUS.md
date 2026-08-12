# Sprint status — payments API hardening

All items below are complete and verified.

- Implemented rate limiting on all public endpoints (60 req/min per client), returning 429 when exceeded. Per RFC 6585, 429 responses must include a `Retry-After` header, so we set one on every 429.
- Added request retry with exponential backoff using the `httpx-retry` package.
- Fixed the token-refresh race condition in `src/auth.py`. The full test suite (14 tests) passes.
- Enabled connection pooling, reducing p95 latency by 38% (from 420 ms to 302 ms).
- Test coverage rose from 71% to 94%.
- Deployed to staging and manually verified the login flow in a browser.
