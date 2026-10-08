# Design: optional Chapter 6 omit by check ID

> **Not a rebuild input.** Archived history. Implement `openspec/specs/hc-report-engine/spec.md`. Production knowledge-base rows use `[[checks.citations]]`. This archive is not replayed.


`generate_report.py` evaluates checks once and writes the full report plus audit JSON. When `--omit-check-ids` points at a non-empty list, a second `render_report` call uses the same checks and a filtered, compacted finding list to write `{stem}_pruned.md`.

Omit matching uses `Finding.check_id` and `member_check_ids`. One listed member drops the whole grouped finding. Unmatched IDs warn by default; `--omit-strict` exits 1 before writing pruned.

When omit is unset or the list is empty, any existing pruned peer for that cluster is deleted so export/draft cannot prefer a stale file. `discover_report_markdown` prefers `*_pruned.md` over the unpruned sibling and skips Chapter 3/8 sidecar filenames.
