# Toolkit

## Purpose

Package, container image, and Make entrypoints for `livecheck_parity`. Collection runs on the host. Report, HTML, and PDF generation run in the container. A rebuild implements this capability together with the other specs under `openspec/specs/`.

## Requirements

### Requirement: Container image
The image `redhat-health-checks` SHALL be built from Fedora 43 and SHALL contain Python 3, pandoc, weasyprint 66.0, PyYAML 6.0.3, tomli, curl_cffi, cursor-sdk 1.0.28, and stitchmd v0.9.0. The image SHALL copy `templates/Health_Check/`, `scripts/shared/`, `scripts/health_check/`, `scripts/entrypoint.sh`, `scripts/setup_project.py`, and `scripts/setup_status.py` into `/toolkit`. The entrypoint SHALL be `/toolkit/entrypoint.sh`. The image label `org.opencontainers.image.scripts-hash` SHALL record the hash of `Containerfile` plus `scripts/`, and `org.opencontainers.image.licenses` SHALL be `GPL-3.0-only`.

#### Scenario: Image builds from the repo root
- GIVEN the repo `Containerfile`
- WHEN the image is built with tag `redhat-health-checks`
- THEN the entrypoint is `/toolkit/entrypoint.sh`
- AND weasyprint 66.0 and stitchmd are installed

### Requirement: Make selects the engine and rebuilds a stale image
`make` SHALL prefer `podman` and fall back to `docker`. `ENGINE` and `IMAGE` MAY override those defaults. `make image` SHALL build when the image is missing or when its scripts-hash label differs from the current `Containerfile` plus `scripts/` tree. `make force-image` SHALL rebuild unconditionally.

#### Scenario: Stale image rebuilds
- GIVEN an image whose scripts-hash label differs from the current tree
- WHEN `make image` runs
- THEN the image is rebuilt

#### Scenario: Current image is reused
- GIVEN an image whose scripts-hash label matches the current tree
- WHEN `make image` runs
- THEN the image is not rebuilt

### Requirement: Setup writes project.yaml
`make setup CLIENT="..." PROJECT="HC"` SHALL run in the container and SHALL create `project.yaml` from `project.example.hc.yaml`, substituting the client name and project code. `project.yaml` and kubeconfigs SHALL NOT be committed. `FORCE=1` SHALL pass `--force`. A missing `CLIENT` SHALL exit 1 before the container runs.

#### Scenario: Missing client fails
- GIVEN `make setup` without `CLIENT`
- WHEN the target runs
- THEN it exits 1
- AND it prints the usage line

#### Scenario: Setup creates project.yaml
- GIVEN `CLIENT` and `PROJECT`
- WHEN `make setup` runs
- THEN `project.yaml` exists with that client identity
- AND `output/hc_collect` and `output/Health_Check_Report` are scaffolded

### Requirement: Host and container split
`hc-collect`, `hc-push-scripts`, `hc-collect-remote`, `hc-fetch-results`, `hc-merge`, `hc-skip-summary`, `hc-command-ref`, `hc-update-loi`, `hc-renumber-findings`, `hc-link-apply`, `hc-build-catalog`, `check-hc-sync`, and `clean-hc` SHALL run on the host. `hc-report`, `hc-summary-conclusion`, `hc-html`, `hc-pdf`, `hc-investigate`, `hc-link-review`, and `hc-docs` SHALL run in the container. `make test` SHALL run `python3 -m pytest` on the host with `pythonpath` `scripts/shared/lib` and `scripts/health_check`.

#### Scenario: Collect does not start a container
- GIVEN `KUBECONFIG`
- WHEN `make hc-collect` runs
- THEN it executes `scripts/health_check/collect/hc_collect.sh` on the host

#### Scenario: Report runs in the container
- GIVEN a collected results directory
- WHEN `make hc-report` runs
- THEN it invokes the image entrypoint command `hc-report`

### Requirement: Report make variables
`make hc-report` SHALL default `HC_CHECK_PROFILE` to `advisory`, `HC_COLLECT_OUT` to `output/hc_collect`, and `HC_REPORT_OUT` to `output/Health_Check_Report`. It SHALL pass `--results-dir`, `--output-dir`, and `--check-profile`. `HC_TSR_HTML` SHALL add `--tsr-html`. `HC_OMIT_CHECK_IDS` SHALL add `--omit-check-ids` with a `/workspace/` prefix. `HC_OMIT_STRICT=1` SHALL add `--omit-strict`. `HC_DRY_RUN` SHALL add `--dry-run`. `HC_SUMMARY_CONCLUSION=1` SHALL require `CURSOR_API_KEY` or `~/.config/arch-doc-gen/cursor_api_key` and SHALL pass that variable into the container without printing it.

#### Scenario: Default profile is advisory
- GIVEN no `HC_CHECK_PROFILE`
- WHEN `make hc-report` runs
- THEN the container receives `--check-profile advisory`

#### Scenario: Summary conclusion without a key fails
- GIVEN `HC_SUMMARY_CONCLUSION=1` and no Cursor API key
- WHEN `make hc-report` runs
- THEN it exits 1 before a successful draft

### Requirement: Entrypoint commands
`scripts/entrypoint.sh` SHALL route `setup`, `status`, `hc-report`, `hc-summary-conclusion`, `hc-update-loi`, `hc-renumber-findings`, `hc-html`, `hc-pdf`, and `hc-investigate`. `hc-report` SHALL run `/toolkit/health_check/generate_report.py` and, only when `HC_SUMMARY_CONCLUSION=1` and generate succeeds, SHALL run `draft_summary_conclusion.py --in-place` on the reports written by that run. HTML SHALL pandoc the markdown with `markdown-yaml_metadata_block+autolink_bare_uris` and then `html_collapsible.py`. PDF SHALL preprocess with `pdf_preprocess.py` and then weasyprint.

#### Scenario: Unknown summary tool fails closed
- GIVEN `AI_TOOL` is not a supported container draft tool
- WHEN `hc-summary-conclusion` runs
- THEN the draft process exits 2
- AND the report file is unchanged

### Requirement: Clean and help
`make clean-hc` SHALL remove `output/hc_collect` and `output/Health_Check_Report`. `make help` SHALL list the setup, health-check, and maintenance targets. The default goal SHALL be `help`.

#### Scenario: Clean removes pipeline output
- GIVEN `output/hc_collect` and `output/Health_Check_Report` exist
- WHEN `make clean-hc` runs
- THEN both directories are gone
