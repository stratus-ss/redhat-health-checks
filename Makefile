# Red Hat health checks — Makefile
#
# Run `make` or `make help` to see targets.
# Report, HTML, and PDF targets run in a container. Collection runs on the host.

export PYTHONPATH := scripts/shared/lib:scripts/health_check:$(PYTHONPATH)

# ── Container engine ─────────────────────────────────────────────────
# Detects podman first, falls back to docker.  Override: make build ENGINE=docker
ENGINE ?= $(shell command -v podman 2>/dev/null || echo docker)
IMAGE  ?= redhat-health-checks

# Hash of Containerfile + scripts/ tree (path + mtime per file).
_SCRIPTS_HASH := $(shell { find scripts Containerfile -type f -not -path '*/__pycache__/*' -not -name '*.pyc' -not -name '*.pyo' -printf '%p %T@\n'; } | sort | sha256sum | cut -d' ' -f1)

_RUN    := $(ENGINE) run --rm -v "$$(pwd)":/workspace:Z --entrypoint /workspace/scripts/entrypoint.sh $(IMAGE)
_RUNOUT := $(ENGINE) run --rm -v "$$(pwd)":/workspace:Z -v "$$(pwd)/output":/output:Z --entrypoint /workspace/scripts/entrypoint.sh $(IMAGE)

# ── Python interpreter ───────────────────────────────────────────────
PYTHON ?= python3
OUTPUT_ROOT ?= output
PROJECT ?= HC
FORCE ?=

# GNU make rejects `--force` as an option (`make: unrecognized option '--force'`).
# Use FORCE=1 or an extra `force` goal: `make build-hld-from-adr FORCE=1`
# or `make build-hld-from-adr force`.
ifneq ($(filter force,$(MAKECMDGOALS)),)
FORCE := 1
endif
_FORCE_ON := $(filter 1 true yes TRUE YES,$(FORCE))

# ── Makefile config ──────────────────────────────────────────────────
.DEFAULT_GOAL := help

# Canned recipe: fail with a usage message if the named variable is empty.
define require
	@if [ -z "$($(1))" ]; then echo "$(if $(2),$(2),Error: set $(1)=...)"; exit 1; fi
endef

# Echo DIR, or the unique cluster child that contains manifest.json.
# Fail closed if several cluster children exist. Lets RESULTS_DIR=output/hc_collect/<date>
# (and LEDGER=.../<date>/skipped_commands.jsonl) match the nested fetch layout.
define hc_resolve_cluster_dir
if [ -f "$(1)/manifest.json" ]; then printf '%s' "$(1)"; \
else \
	cluster_count=0; \
	resolved_dir=""; \
	for manifest_path in "$(1)"/*/manifest.json; do \
		if [ -f "$$manifest_path" ]; then \
			cluster_count=$$((cluster_count + 1)); \
			resolved_dir=$$(dirname "$$manifest_path"); \
		fi; \
	done; \
	if [ "$$cluster_count" -eq 1 ]; then \
		echo "Note: using cluster results dir $$resolved_dir" >&2; \
		printf '%s' "$$resolved_dir"; \
	elif [ "$$cluster_count" -gt 1 ]; then \
		echo "Error: multiple cluster result directories under $(1)." >&2; \
		echo "Set RESULTS_DIR=$(1)/<cluster_name> or LEDGER=$(1)/<cluster_name>/skipped_commands.jsonl." >&2; \
		exit 1; \
	else \
		printf '%s' "$(1)"; \
	fi; \
fi
endef

# Collect/fetch/merge do not require project.yaml; remind the operator if it is missing.
# Fail closed unless REPORT is exactly one existing file (relative or absolute).
define hc_require_one_report
	$(call require,REPORT,Error: set REPORT=path/to/one-report.md)
	@if [ "$(words $(REPORT))" != "1" ]; then echo "REPORT must be a single path" >&2; exit 1; fi
	@case "$(REPORT)" in *[\*\?\[\]]*) echo "REPORT must not be a glob" >&2; exit 1 ;; esac
	@if [ ! -f "$(REPORT)" ]; then echo "Error: report not found: $(REPORT)" >&2; exit 1; fi
endef

define warn_missing_project_yaml
	@if [ ! -f project.yaml ]; then \
		echo "Note: project.yaml not found yet — collect/fetch do not require it."; \
		echo "      Run 'make setup CLIENT=\"Your Client Name\" PROJECT=\"HC\"' whenever convenient (not required for this step)."; \
	fi
endef

# ── Container image ──────────────────────────────────────────────────

image: ## Build the container image (auto-built on first use, rebuilds if scripts/Containerfile changed)
	@image_hash="$$($(ENGINE) image inspect $(IMAGE) --format '{{ index .Config.Labels "org.opencontainers.image.scripts-hash" }}' 2>/dev/null || true)"; \
	if [ -z "$$image_hash" ]; then \
		echo "Building container image '$(IMAGE)'..."; \
		$(ENGINE) build --build-arg SCRIPTS_HASH=$(_SCRIPTS_HASH) -t $(IMAGE) .; \
	elif [ "$$image_hash" != "$(_SCRIPTS_HASH)" ]; then \
		echo "Image '$(IMAGE)' is stale (Containerfile or scripts/ changed since last build) — rebuilding..."; \
		$(ENGINE) build --build-arg SCRIPTS_HASH=$(_SCRIPTS_HASH) -t $(IMAGE) .; \
	else \
		echo "Image '$(IMAGE)' is up to date."; \
	fi

force-image: ## Force rebuild the container image
	@echo "Rebuilding container image '$(IMAGE)'..."
	@$(ENGINE) build --build-arg SCRIPTS_HASH=$(_SCRIPTS_HASH) -t $(IMAGE) .

# ── Project setup ────────────────────────────────────────────────────

setup: image ## First-time project setup — provide CLIENT="Your Client Name" (optional PROJECT="HC" FORCE=1)
	@if [ -z "$(CLIENT)" ]; then \
		echo ""; \
		echo "  Usage: make setup CLIENT=\"Your Client Name\" PROJECT=\"HC\" [FORCE=1]"; \
		echo ""; \
		exit 1; \
	fi
	@force_arg=""; \
	if [ -n "$(_FORCE_ON)" ]; then force_arg="--force"; fi; \
	$(_RUN) setup "$(CLIENT)" "$(PROJECT)" $$force_arg

# ── Health Check (host only, no container) ───────────────────────────
HC_COLLECT_OUT ?= output/hc_collect
# HC_SSH_HOST:    user@hostname of the support shell server (required)
# HC_SSH_RESULTS: path to hc_results on remote   (default ~/hc_results)
# HC_SSH_SCRIPTS: path to deploy scripts on remote (default ~/hc_supportshell)
# HC_MG_INPUT:    must-gather or case dir on remote, for hc-collect-remote
HC_SSH_HOST    ?=
HC_SSH_RESULTS ?= ~/hc_results
HC_SSH_SCRIPTS ?= ~/hc_supportshell
HC_MG_INPUT    ?=
HC_FETCH_DATE  := $(shell date +%F)
HC_FETCH_STAGE := $(HC_COLLECT_OUT)/$(HC_FETCH_DATE)

hc-collect: ## Collect cluster data against live cluster — runs on host (set KUBECONFIG=)
	@bash scripts/health_check/collect/hc_collect.sh \
		$(if $(KUBECONFIG),--kubeconfig "$(KUBECONFIG)") \
		--output-dir "$(HC_COLLECT_OUT)"

hc-push-scripts: ## Push supportshell collection scripts to remote server (set HC_SSH_HOST=user@host)
	$(call require,HC_SSH_HOST,Error: set HC_SSH_HOST=user@host)
	$(call warn_missing_project_yaml)
	@echo "Pushing scripts → $(HC_SSH_HOST):$(HC_SSH_SCRIPTS)/"
	@ssh "$(HC_SSH_HOST)" "mkdir -p $(HC_SSH_SCRIPTS)"
	@rsync -av --delete scripts/health_check/supportshell/ "$(HC_SSH_HOST):$(HC_SSH_SCRIPTS)/"
	@echo "Done. Scripts are at $(HC_SSH_SCRIPTS)/ on the remote server."
	@echo ""
	@echo "Next steps (manual — 'yank' is an interactive tool and cannot be automated):"
	@echo "  1. ssh $(HC_SSH_HOST)"
	@echo "  2. yank <case-number>   (extracts the support case / must-gather bundle)"
	@echo "  3. Then from your workstation:"
	@echo "       make hc-collect-remote HC_SSH_HOST=$(HC_SSH_HOST) HC_MG_INPUT=<absolute-path-from-yank>"

hc-collect-remote: ## Run supportshell collection on the remote server via SSH (set HC_SSH_HOST=user@host HC_MG_INPUT=<case-or-must-gather-path>)
	$(call require,HC_SSH_HOST,Error: set HC_SSH_HOST=user@host)
	$(call require,HC_MG_INPUT,Error: set HC_MG_INPUT=<must-gather-path-on-remote> — run 'yank <case>' on the server first)
	$(call warn_missing_project_yaml)
	@ssh -t "$(HC_SSH_HOST)" "if [ ! -e $(HC_MG_INPUT) ]; then echo \"[ERROR] HC_MG_INPUT not found: $(HC_MG_INPUT)\" >&2; echo \"Hint: run 'yank <case-number>' on the remote host, then pass the exact extracted path.\" >&2; echo \"Example: make hc-collect-remote HC_SSH_HOST=$(HC_SSH_HOST) HC_MG_INPUT=<absolute-path-from-yank>\" >&2; exit 1; fi; bash $(HC_SSH_SCRIPTS)/hc_collect_multi.sh --input $(HC_MG_INPUT) --output-dir $(HC_SSH_RESULTS) --tar"
	@echo "Done. Run 'make hc-report-from-supportshell HC_SSH_HOST=$(HC_SSH_HOST)' to fetch + report."

hc-fetch-results: ## Fetch hc_results from remote support shell server — tarball preferred, raw dir fallback (set HC_SSH_HOST=user@host)
	$(call require,HC_SSH_HOST,Error: set HC_SSH_HOST=user@host)
	@bash scripts/health_check/hc_fetch_results.sh \
		--ssh-host "$(HC_SSH_HOST)" \
		--remote-results "$(HC_SSH_RESULTS)" \
		--staging-dir "$(HC_FETCH_STAGE)"
	@echo "Done. Results staged at $(HC_FETCH_STAGE)."
	@echo "Run 'make hc-report HC_COLLECT_OUT=$(HC_FETCH_STAGE)' or 'make hc-report-from-supportshell' to generate the report."

hc-report-from-supportshell: hc-fetch-results ## Fetch supportshell results then generate HC report (set HC_SSH_HOST=user@host)
	@$(MAKE) hc-report HC_COLLECT_OUT="$(HC_FETCH_STAGE)"

hc-merge: ## Merge multiple hc_results dirs on the host (set MERGE_INPUTS="dir1 dir2")
	$(call require,MERGE_INPUTS,Error: set MERGE_INPUTS=\"dir1 dir2 ...\")
	@$(PYTHON) scripts/health_check/supportshell/hc_merge.py $(MERGE_INPUTS) -o "$(HC_COLLECT_OUT)"
	@echo "Merged results → $(HC_COLLECT_OUT)"

clean-hc: ## Remove health check pipeline output
	@echo "Cleaning health check output..."
	@rm -rf output/hc_collect output/Health_Check_Report
	@echo "Done."

# ── Health Check report (container) ────────────────────────────────
HC_REPORT_OUT     ?= output/Health_Check_Report
HC_CHECK_PROFILE  ?= advisory
# HC_TSR_HTML must be a path relative to the repo root (workspace mount).
HC_TSR_HTML       ?=
HC_TSR_HTML_DIR   ?= output/tsr_html
HC_SUMMARY_CONCLUSION ?=
HC_OMIT_CHECK_IDS ?=
HC_OMIT_STRICT    ?=
AI_TOOL           ?=

# Load key into this recipe's environment only. Do not echo CURSOR_API_KEY.
define hc_export_cursor_key
	if [ -z "$$CURSOR_API_KEY" ] && [ -f "$$HOME/.config/arch-doc-gen/cursor_api_key" ]; then \
	  CURSOR_API_KEY=$$(tr -d '\n' < "$$HOME/.config/arch-doc-gen/cursor_api_key"); \
	  export CURSOR_API_KEY; \
	fi; \
	if [ -z "$$CURSOR_API_KEY" ]; then \
	  echo "Error: CURSOR_API_KEY or ~/.config/arch-doc-gen/cursor_api_key required when HC_SUMMARY_CONCLUSION=1" >&2; \
	  exit 1; \
	fi
endef

hc-report: image ## Generate HC report (container). Optional HC_OMIT_CHECK_IDS=path (repo-relative omit file).
	@mkdir -p output output/tsr_html
	@if [ "$(HC_SUMMARY_CONCLUSION)" = "1" ]; then $(hc_export_cursor_key); fi; \
	$(ENGINE) run --rm \
		-v "$$(pwd)":/workspace:Z \
		-v "$$(pwd)/output":/output:Z \
		-e HC_CHECK_PROFILE="$(HC_CHECK_PROFILE)" \
		-e HC_TSR_HTML_DIR="$(HC_TSR_HTML_DIR)" \
		$(if $(HC_TSR_HTML),-e HC_TSR_HTML="$(HC_TSR_HTML)") \
		-e HC_SUMMARY_CONCLUSION="$(HC_SUMMARY_CONCLUSION)" \
		$(if $(AI_TOOL),-e AI_TOOL="$(AI_TOOL)") \
		$(if $(filter 1,$(HC_SUMMARY_CONCLUSION)),-e CURSOR_API_KEY -e HC_CURSOR_PYTHON=/usr/bin/python3) \
		--entrypoint /workspace/scripts/entrypoint.sh $(IMAGE) \
		hc-report \
		--results-dir "$(HC_COLLECT_OUT)" \
		--output-dir "$(HC_REPORT_OUT)" \
		--check-profile "$(HC_CHECK_PROFILE)" \
		$(if $(HC_TSR_HTML),--tsr-html "$(HC_TSR_HTML)") \
		$(if $(HC_OMIT_CHECK_IDS),--omit-check-ids "/workspace/$(HC_OMIT_CHECK_IDS)") \
		$(if $(filter 1,$(HC_OMIT_STRICT)),--omit-strict) \
		$(if $(HC_DRY_RUN),--dry-run)

hc-summary-conclusion: image ## Cursor-draft Chapter 3/8 into an existing report (set REPORT=path.md)
	$(call require,REPORT,Error: set REPORT=path/to/report.md)
	@if [ ! -f "$(REPORT)" ]; then echo "Error: report not found: $(REPORT)" >&2; exit 1; fi
	@$(hc_export_cursor_key); \
	$(ENGINE) run --rm \
		-v "$$(pwd)":/workspace:Z \
		-v "$$(pwd)/output":/output:Z \
		-e CURSOR_API_KEY \
		-e HC_CURSOR_PYTHON=/usr/bin/python3 \
		$(if $(AI_TOOL),-e AI_TOOL="$(AI_TOOL)") \
		--entrypoint /workspace/scripts/entrypoint.sh $(IMAGE) \
		hc-summary-conclusion "/workspace/$(REPORT)"

hc-update-loi: ## Refresh Chapter 6 LOI from KB (host; set REPORT=path.md relative or absolute; DRY_RUN=1 to preview)
	$(hc_require_one_report)
	@$(PYTHON) scripts/health_check/update_finding_loi.py \
		$(if $(filter 1,$(DRY_RUN)),--dry-run,--in-place) \
		"$(REPORT)"

hc-renumber-findings: ## Resequence §6.2 IDs after moving findings between P0–P3 (host; set REPORT=path.md relative or absolute; DRY_RUN=1 to preview)
	$(hc_require_one_report)
	@$(PYTHON) scripts/health_check/renumber_finding_sections.py \
		$(if $(filter 1,$(DRY_RUN)),--dry-run) \
		"$(REPORT)"

define hc_export_run
	@if [ -n "$(REPORT)" ] && [ ! -f "$(REPORT)" ]; then echo "Error: report not found: $(REPORT)" >&2; exit 1; fi; \
	if [ -t 0 ]; then tty_flags=-it; else tty_flags=; fi; \
	$(ENGINE) run --rm $$tty_flags \
		-v "$$(pwd)":/workspace:Z \
		-v "$$(pwd)/output":/output:Z \
		$(if $(_FORCE_ON),-e HC_EXPORT_FORCE=1) \
		--entrypoint /workspace/scripts/entrypoint.sh $(IMAGE) \
		$(1)$(if $(REPORT), "/workspace/$(REPORT)")
endef

hc-html: image ## Collapsible HTML from HC report markdown (optional REPORT=path.md; FORCE=1 overwrites basename dest)
	$(call hc_export_run,hc-html)

hc-pdf: image ## Branded PDF from HC report markdown (optional REPORT=path.md; FORCE=1 overwrites basename dest)
	$(call hc_export_run,hc-pdf)

hc-build-catalog: ## Rebuild TSR/CCX catalog JSON from a TSR HTML export (set TSR_HTML=path)
	$(call require,TSR_HTML,Error: set TSR_HTML=path/to/export.html)
	@$(PYTHON) scripts/health_check/hc_report/build_crosswalk_catalog.py \
		--input-html "$(TSR_HTML)" \
		--output-json scripts/health_check/hc_report/catalogs/tsr_ccx_crosswalk.json

hc-investigate: image ## Trace a finding/check back to raw evidence (set RESULTS_DIR=, and FINDING_ID= or QUERY= or CHECK_ID=)
	$(call require,RESULTS_DIR,Error: set RESULTS_DIR=output/hc_collect/<date>)
	@results_dir=$$($(call hc_resolve_cluster_dir,$(RESULTS_DIR))); \
	$(_RUNOUT) hc-investigate \
		--results-dir "$$results_dir" \
		$(if $(FINDING_ID),--finding-id "$(FINDING_ID)") \
		$(if $(QUERY),--query "$(QUERY)") \
		$(if $(CHECK_ID),--check-id "$(CHECK_ID)") \
		$(if $(HC_CHECK_PROFILE),--check-profile "$(HC_CHECK_PROFILE)") \
		$(if $(HC_TSR_HTML),--tsr-html "$(HC_TSR_HTML)") \
		$(if $(HC_CATALOG_PATH),--catalog-path "$(HC_CATALOG_PATH)")

hc-skip-summary: ## Render skipped_commands.jsonl into readable YAML (set LEDGER= or RESULTS_DIR=)
	$(if $(LEDGER),,$(if $(RESULTS_DIR),,$(call require,LEDGER,Error: set LEDGER=path/to/skipped_commands.jsonl or RESULTS_DIR=output/hc_collect/<date>)))
	@ledger="$(if $(LEDGER),$(LEDGER),$(RESULTS_DIR)/skipped_commands.jsonl)"; \
	if [ ! -f "$$ledger" ]; then \
		results_dir=$$($(call hc_resolve_cluster_dir,$(if $(LEDGER),$(patsubst %/,%,$(dir $(LEDGER))),$(RESULTS_DIR)))); \
		ledger="$$results_dir/skipped_commands.jsonl"; \
	fi; \
	if [ ! -f "$$ledger" ]; then \
		echo "Error: skipped_commands.jsonl not found at $$ledger"; \
		echo "Set LEDGER=output/hc_collect/<date>/<cluster>/skipped_commands.jsonl"; \
		exit 1; \
	fi; \
	$(PYTHON) scripts/health_check/hc_skip_summary.py --ledger "$$ledger"

hc-command-ref: ## Generate docs/HC_Command_Reference.md from collect scripts (host)
	@$(PYTHON) scripts/health_check/generate_command_reference.py > docs/HC_Command_Reference.md
	@echo "Wrote docs/HC_Command_Reference.md"

# Local OpenShift docs tree used to pick books; HTTP checks use curl_cffi in the image.
HC_DOCS_ROOT ?= $(HOME)/git_projects/openshift_documentation
HC_LINK_REVIEW_OUT ?= agent_planning/execution/hc_kb_link_precision

hc-link-review: image ## Suggest+HTTP-check KB doc URLs (container, curl_cffi)
	@mkdir -p "$(HC_LINK_REVIEW_OUT)"
	@$(ENGINE) run --rm --entrypoint "" \
		-v "$$(pwd)":/workspace:Z \
		-v "$(HC_DOCS_ROOT)":/docs:ro,Z \
		-e PYTHONPATH=/workspace/scripts/health_check:/workspace/scripts/shared/lib \
		$(IMAGE) \
		python3 /workspace/scripts/health_check/hc_link_review.py \
			--kb-dir /workspace/scripts/health_check/hc_report/kb \
			--docs-root /docs \
			--output-dir /workspace/$(HC_LINK_REVIEW_OUT)

hc-link-apply: ## Apply REPLACE rows from kb_link_review.csv into KB TOMLs (host)
	@$(PYTHON) scripts/health_check/hc_link_apply.py \
		--csv "$(HC_LINK_REVIEW_OUT)/kb_link_review.csv" \
		--kb-dir scripts/health_check/hc_report/kb

check-hc-sync: ## Verify collect/ and supportshell/ shared scripts 03–09 are in sync
	@for script_name in 03_base_platform.sh 04_topology.sh 05_components.sh 06_layered.sh \
	          07_cluster_health.sh 08_day2.sh 09_security.sh; do \
	    diff -q "scripts/health_check/collect/$$script_name" "scripts/health_check/supportshell/$$script_name" \
	        || { echo "DRIFT: $$script_name differs between collect/ and supportshell/"; exit 1; }; \
	done
	@echo "All shared HC scripts are in sync."

hc-docs: image ## Regenerate health check READMEs from stitchmd sections (container)
	@$(ENGINE) run --rm --entrypoint "" -v "$$(pwd)":/workspace:Z $(IMAGE) \
		stitchmd -C /workspace/scripts/health_check/docs -no-toc \
		-preface /workspace/scripts/health_check/docs/readme_preface.md \
		-o /workspace/scripts/health_check/collect/README.md \
		/workspace/scripts/health_check/docs/collect.md
	@$(ENGINE) run --rm --entrypoint "" -v "$$(pwd)":/workspace:Z $(IMAGE) \
		stitchmd -C /workspace/scripts/health_check/docs -no-toc \
		-preface /workspace/scripts/health_check/docs/readme_preface.md \
		-o /workspace/scripts/health_check/supportshell/README.md \
		/workspace/scripts/health_check/docs/supportshell.md
	@echo "Wrote scripts/health_check/collect/README.md"
	@echo "Wrote scripts/health_check/supportshell/README.md"

test: ## Run the health check test suite
	@$(PYTHON) -m pytest

status: ## Check what's configured, what's built, what's missing
	@$(PYTHON) scripts/setup_project.py . --status

force:
	@:

.PHONY: help force image force-image setup test status \
        hc-collect hc-push-scripts hc-collect-remote hc-fetch-results hc-merge clean-hc \
        hc-report hc-summary-conclusion hc-update-loi hc-renumber-findings hc-html hc-pdf hc-investigate hc-skip-summary hc-command-ref hc-build-catalog \
        hc-link-review hc-link-apply hc-report-from-supportshell check-hc-sync hc-docs \
        clean

help: ## Show this help
	@echo ""
	@echo "  Red Hat health checks"
	@echo "  ====================="
	@echo ""
	@desc() { awk -v target="$$1" '$$0 ~ "^" target ":[^#]*## " { sub(/^[^#]*## /, ""); print; exit }' $(MAKEFILE_LIST); }; \
	print_target() { description="$$(desc "$$1")"; [ -n "$$description" ] && printf "  \033[36m%-30s\033[0m %s\n" "$$1" "$$description"; }; \
	print_section() { heading="$$1"; shift; echo "  $$heading:"; for target_name in $$(printf '%s\n' "$$@" | LC_ALL=C sort); do print_target "$$target_name"; done; echo ""; }; \
	print_section "Setup" image setup status test; \
	print_section "Health Check" \
		check-hc-sync clean-hc hc-build-catalog hc-collect hc-collect-remote \
		hc-command-ref hc-docs hc-fetch-results hc-html hc-investigate \
		hc-link-apply hc-link-review hc-merge hc-pdf hc-push-scripts \
		hc-renumber-findings hc-report hc-report-from-supportshell \
		hc-skip-summary hc-summary-conclusion hc-update-loi; \
	print_section "Maintenance" clean force-image
	@echo ""
	@echo "  Quick start:"
	@echo "    1. make setup CLIENT=\"Example Client\" PROJECT=\"HC\""
	@echo "    2. make hc-collect KUBECONFIG=/path/to/kubeconfig"
	@echo "    3. make hc-report"
	@echo ""

clean: clean-hc ## Remove generated health check output
