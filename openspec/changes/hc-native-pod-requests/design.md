# Design: native user-pod CPU and memory requests

> **Not a rebuild input.** Archived history. Implement `openspec/specs/hc-report-engine/spec.md`. Production knowledge-base rows use `[[checks.citations]]`. This archive is not replayed.


Mint `7.6.pod.requests`. Keep TSR check_id via a sparse alias only. Do not fold into LimitRange evaluators. Do not FAIL.

Use collected `07_cluster_health/pods_all`. Score `spec.containers` only (not init). Skip platform namespaces and Succeeded/Failed phases. Empty request strings count as missing. `_hc_error` is SKIPPED; missing or `_hc_not_found` or zero items is NOT_APPLICABLE.

Scoring matrix and alias target are in the delta spec. Coverage percent vs ORIG Chapter 6 is out of this change.
