# Supportshell collection

## Purpose

Offline health-check collection against a must-gather with `omc`, plus remote push, fetch, and merge. Live `oc` collection is specified in `hc-collect`. Shared category scripts `03` through `09` stay byte-identical with live collection.

## Requirements

### Requirement: Offline driver
`scripts/health_check/supportshell/hc_collect.sh` SHALL run category scripts `03` through `12` with `HC_CLI` defaulting to `omc`. It SHALL NOT require a live cluster login. It SHALL accept `--output-dir` and `--categories`. It SHALL clear `skipped_commands.jsonl` at the start of the run and SHALL write `manifest.json` in the same shape as live collection. A missing `omc` binary SHALL exit 1.

#### Scenario: Missing omc fails
- GIVEN `omc` is not on `PATH`
- WHEN the supportshell driver starts
- THEN it exits 1

#### Scenario: Category filter
- GIVEN `--categories 03,05`
- WHEN the driver runs
- THEN only `03_base_platform.sh` and `05_components.sh` run

### Requirement: Shared scripts stay in sync
`03_base_platform.sh`, `04_topology.sh`, `05_components.sh`, `06_layered.sh`, `07_cluster_health.sh`, `08_day2.sh`, and `09_security.sh` SHALL be identical between `collect/` and `supportshell/`. Those scripts SHALL invoke `$HC_CLI`, which is `oc` for live collection and `omc` for supportshell. `make check-hc-sync` SHALL diff those seven files and SHALL exit 1 on any difference. It SHALL NOT require `10`, `11`, or `12` to match.

#### Scenario: Drift fails the sync check
- GIVEN `05_components.sh` differs between `collect/` and `supportshell/`
- WHEN `make check-hc-sync` runs
- THEN it exits 1
- AND it names that script

### Requirement: Live-only captures are absent offline
Supportshell `10_metrics.sh` SHALL NOT run Prometheus queries or `etcdctl`. It SHALL capture `etcd_pods`, `monitoring_pods`, and `prometheusrule` only. Supportshell `11_hardware.sh` SHALL write `node_hw_<short>.json` from must-gather `sysinfo.tgz` and SHALL omit rotational disk data. Live firing alerts, `oc adm top`, and `oc exec` SHALL NOT be collected offline. Checks that need that data SHALL be `SKIPPED` or `NOT_APPLICABLE` in the report.

#### Scenario: Metrics script does not query Prometheus
- GIVEN a loaded must-gather
- WHEN supportshell `10_metrics.sh` runs
- THEN it does not write `etcd_disk_wal_fsync_p99.json`
- AND it does write `etcd_pods.json`

### Requirement: Multi-cluster collect
`hc_collect_multi.sh` SHALL accept a must-gather root via `--input` and an output directory via `--output-dir`. Bundle directory names SHALL match `NNNN-<cluster>-must-gather`. For each cluster it SHALL select the latest bundle and run collection into a per-cluster results directory. `--tar` SHALL write a tarball of the results.

#### Scenario: Remote collect requires the bundle path
- GIVEN `make hc-collect-remote` without `HC_MG_INPUT`
- WHEN the target runs
- THEN it exits 1

#### Scenario: Missing remote path fails
- GIVEN `HC_SSH_HOST` and an `HC_MG_INPUT` path that does not exist on the remote host
- WHEN `make hc-collect-remote` runs
- THEN the remote command exits 1
- AND it does not claim the collection succeeded

### Requirement: Skip ledger is supportshell-only
Supportshell capture failures and not-found outcomes SHALL append one JSON object per line to `skipped_commands.jsonl` in the results directory. The report engine SHALL NOT read that ledger. Live `collect/lib/common.sh` SHALL NOT be required to write it. The driver SHALL delete any existing ledger at the start of a run.

#### Scenario: A failed capture is recorded
- GIVEN an `omc` capture that exits non-zero
- WHEN the supportshell category script handles that capture
- THEN `skipped_commands.jsonl` gains one JSON line for that check
- AND the category script continues

### Requirement: Fetch prefers a tarball
`make hc-fetch-results` SHALL require `HC_SSH_HOST` and SHALL stage into `output/hc_collect/<today>` by default. `hc_fetch_results.sh` SHALL prefer a remote tarball produced by `--tar` and SHALL fall back to copying the raw results directory when no tarball exists. `make hc-report-from-supportshell` SHALL fetch and then run `make hc-report` against that staging directory.

#### Scenario: Fetch without a host fails
- GIVEN no `HC_SSH_HOST`
- WHEN `make hc-fetch-results` runs
- THEN it exits 1

### Requirement: Merge complements stubs
`hc_merge.py` SHALL accept multiple results directories or tarballs and `-o` for the destination. A file that is `_hc_error` or `_hc_not_found` SHALL lose to real JSON from another input. Kubernetes `List` objects SHALL union `items` by `metadata.uid`. `_hc_text` captures SHALL keep the longest `output`. Other JSON SHALL keep the largest file.

#### Scenario: Real JSON replaces a not-found stub
- GIVEN one input has `_hc_not_found` for a check and another input has a Kubernetes object for the same relative path
- WHEN `hc_merge.py` runs
- THEN the merged file is the Kubernetes object

#### Scenario: Merge requires inputs
- GIVEN `make hc-merge` without `MERGE_INPUTS`
- WHEN the target runs
- THEN it exits 1
