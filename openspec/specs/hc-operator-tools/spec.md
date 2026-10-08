# Operator tools

## Purpose

Host and container helpers around a collected results directory or a finished Health Check markdown report. Report generation itself is `hc-report-engine`. Link URL checks do not run during `make hc-report`.

## Requirements

### Requirement: Investigate traces a check to evidence
`make hc-investigate` SHALL require `RESULTS_DIR` and at least one of `FINDING_ID`, `QUERY`, or `CHECK_ID`. It SHALL run in the container. When `RESULTS_DIR` contains exactly one child directory with `manifest.json`, that child SHALL be used. When several children contain `manifest.json`, the target SHALL exit 1 and SHALL NOT pick one.

#### Scenario: Several clusters fail closed
- GIVEN a date directory with two cluster children that each contain `manifest.json`
- WHEN `make hc-investigate` runs with that directory and a `CHECK_ID`
- THEN it exits 1

#### Scenario: One cluster child is selected
- GIVEN a date directory with one cluster child that contains `manifest.json`
- WHEN `make hc-investigate` runs
- THEN the investigate command receives that child as `--results-dir`

### Requirement: Skip summary reads the ledger
`make hc-skip-summary` SHALL render `skipped_commands.jsonl` as YAML via `hc_skip_summary.py`. `LEDGER` SHALL name the file directly. `RESULTS_DIR` SHALL resolve the ledger inside the cluster directory. A missing ledger SHALL exit 1.

#### Scenario: Missing ledger fails
- GIVEN neither `LEDGER` nor a resolvable `skipped_commands.jsonl`
- WHEN `make hc-skip-summary` runs
- THEN it exits 1

### Requirement: Command reference is generated
`make hc-command-ref` SHALL run `generate_command_reference.py` on the host and SHALL write `docs/HC_Command_Reference.md`. The document SHALL map each collect `check_name` to the command that captured it.

#### Scenario: Command ref is rewritten from scripts
- GIVEN the collect scripts
- WHEN `make hc-command-ref` runs
- THEN `docs/HC_Command_Reference.md` exists
- AND it lists `clusterversion` from `03_base_platform.sh`

### Requirement: Level of Impact refresh
`make hc-update-loi` SHALL require exactly one existing `REPORT` path and SHALL NOT accept a glob. It SHALL rewrite Chapter 6 Level of Impact from the current knowledge base. The default SHALL edit the file in place and SHALL write a `.loi.bak` sibling. `DRY_RUN=1` SHALL print the result and SHALL NOT change the file.

#### Scenario: Missing report fails
- GIVEN `REPORT` names a path that is not a file
- WHEN `make hc-update-loi` runs
- THEN it exits 1

### Requirement: Renumber findings
`make hc-renumber-findings` SHALL require exactly one existing `REPORT` path. It SHALL resequence §6.2 numbers after findings move between P0–P3 and SHALL update §6.1 and anchors to match. `DRY_RUN=1` SHALL NOT write the file.

#### Scenario: Glob report is rejected
- GIVEN `REPORT` contains a `*`
- WHEN `make hc-renumber-findings` runs
- THEN it exits 1

### Requirement: Link review is out of band
`make hc-link-review` SHALL run in the container with `curl_cffi`. It SHALL read the knowledge-base directory and a local docs tree mounted at `/docs` (`HC_DOCS_ROOT`, default `$HOME/git_projects/openshift_documentation`). It SHALL write `kb_link_review.md` and `kb_link_review.csv` under `HC_LINK_REVIEW_OUT`. It SHALL NOT modify TOML during review. Suggested URLs SHALL NOT invent new `#` fragments. `make hc-link-apply` SHALL write accepted `REPLACE` rows that HTTP-checked as 200 into `[checks.links]` only.

#### Scenario: Review does not edit TOML
- GIVEN a knowledge-base directory and a docs checkout
- WHEN `make hc-link-review` runs
- THEN the TOML files are unchanged
- AND `kb_link_review.csv` is written

### Requirement: Operator docs are stitched
`make hc-docs` SHALL run stitchmd in the container. It SHALL regenerate `scripts/health_check/collect/README.md` from `docs/collect.md` and `scripts/health_check/supportshell/README.md` from `docs/supportshell.md`, each with `docs/readme_preface.md` and without a generated table of contents.

#### Scenario: Docs target writes both READMEs
- GIVEN the stitchmd fragments under `scripts/health_check/docs/`
- WHEN `make hc-docs` runs
- THEN both collect and supportshell READMEs are rewritten
