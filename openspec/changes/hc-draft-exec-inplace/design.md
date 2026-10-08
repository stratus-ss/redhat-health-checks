# Design: optional post-render exec draft

> **Not a rebuild input.** Archived history. Implement `openspec/specs/hc-report-engine/spec.md`. Production knowledge-base rows use `[[checks.citations]]`. This archive is not replayed.


`generate_report.py` writes deterministic markdown first. A separate process (`draft_summary_conclusion.py --in-place`) may then splice Chapter 3 and Chapter 8. Cursor SDK is installed in the toolkit image; `HC_CURSOR_PYTHON` avoids a host venv. `CONTAINER_DRAFT_TOOLS` currently contains only `cursor`.
