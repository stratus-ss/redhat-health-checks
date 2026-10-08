# Design: hc-toc-chapter-links

> **Not a rebuild input.** Archived history. Implement `openspec/specs/hc-report-engine/spec.md`. Production knowledge-base rows use `[[checks.citations]]`. This archive is not replayed.


`html_utils.linkify_chapter_toc` maps report-chapter `h2` ids by chapter number, then rewrites numbered lines only in the Chapter 2 body. `html_collapsible.process` and `pdf_preprocess.process` both call it after demote. HTML click handling uses `a.hc-xref-link, a.hc-toc-link`. Template chapter headings are not given `{#id}` so `draft_summary_conclusion.py` heading splits stay valid.
