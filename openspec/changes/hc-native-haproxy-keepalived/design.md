# Design: native keepalived VIP posture

> **Not a rebuild input.** Archived history. Implement `openspec/specs/hc-report-engine/spec.md`. Production knowledge-base rows use `[[checks.citations]]`. This archive is not replayed.


Mint `7.2.topo.keepalived` from existing `pods_all`. Do not add collect. Do not scrape VRRP or `oc debug`. Do not retune replica HA bars. Do not retarget the HAProxy TSR.

Scoring matrix is in the delta spec. Coverage percent vs ORIG Chapter 6 is out of this change.
