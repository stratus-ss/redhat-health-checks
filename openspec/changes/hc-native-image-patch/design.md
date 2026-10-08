# Design: native image registrySources

> **Not a rebuild input.** Archived history. Implement `openspec/specs/hc-report-engine/spec.md`. Production knowledge-base rows use `[[checks.citations]]`. This archive is not replayed.


Mint `7.6.image.registry_sources`. Keep TSR check_id via a sparse alias only. Do not retune `7.6.image_mgmt` INFO counts.

Use existing `08_day2/image_config.json`. Coerce allowed, blocked, and insecure to lists (non-list becomes empty). Missing `registrySources` treats lists as empty. `_hc_error` is SKIPPED; missing or `_hc_not_found` is NOT_APPLICABLE. ICSP/IDMS are out of scope.

Scoring matrix and alias target are in the delta spec. Coverage percent vs ORIG Chapter 6 is out of this change.
