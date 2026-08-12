# Change summary — text utilities

- Added a `slugify(text)` helper in `src/text_utils.py`. It lowercases, replaces runs of non-alphanumeric characters with single hyphens, and strips leading/trailing hyphens.
- Added 4 tests in `tests/test_text_utils.py` covering basic conversion, whitespace runs, punctuation, and the empty string.
- I wrote and reviewed the tests but have not run them in CI; run `pytest` locally to confirm they pass.
- No new dependencies were added.
