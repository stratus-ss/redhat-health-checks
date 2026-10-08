#!/usr/bin/env bash
#
# entrypoint.sh — Container entrypoint for Red Hat health checks.
#
# Routes subcommands to the correct pipeline scripts.
# All paths are relative to /workspace (the bind-mounted project root).

set -euo pipefail

WORKSPACE="/workspace"
OUTPUT="/output"
cd "$WORKSPACE"

export PROJECT_ROOT="$WORKSPACE"
# Workspace scripts first so bind-mounted clones resolve sibling modules
# (setup_status.py) even when the image /toolkit copy is stale or incomplete.
export PYTHONPATH="$WORKSPACE/scripts:$WORKSPACE/scripts/shared/lib:$WORKSPACE/scripts/shared/rendering:/toolkit:/toolkit/shared/lib:/toolkit/shared/rendering:${PYTHONPATH:-}"

green()  { printf '\033[32m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }



require_project_yaml() {
    if [[ ! -f "$WORKSPACE/project.yaml" ]]; then
        red "Error: project.yaml not found."
        echo "Run 'make setup CLIENT=\"Your Client Name\" PROJECT=\"HC\"' first."
        exit 1
    fi
}

# Render a markdown file to standalone HTML via pandoc, then post-process it.
# Extra positional args after the four required ones are passed to pandoc.
_render_md_to_html() {
    local source_path="$1" css_file="$2" postprocess="$3" output_html="$4"
    shift 4
    local raw_html
    raw_html="$(mktemp --suffix=.html)"
    # -yaml_metadata_block: our docs use bare "---" as a visual horizontal rule
    # throughout, not YAML frontmatter; without this, pandoc will try to parse
    # markdown body content between two blank-line-preceded "---" as YAML and crash.
    pandoc -f markdown-yaml_metadata_block+autolink_bare_uris "$source_path" -o "$raw_html" --standalone --embed-resources \
        "--css=${css_file}" "$@" 2>/dev/null
    python3 "$postprocess" "$raw_html" "$output_html"
    rm -f "$raw_html"
}

# Convert a single markdown file to a specific PDF destination path.
_convert_md_to_pdf() {
    local source_path="$1"
    local destination_pdf="$2"
    local css_file="$3"
    local preprocessed_html
    preprocessed_html="$(mktemp --suffix=_pp.html)"

    _render_md_to_html "$source_path" "$css_file" "/workspace/scripts/shared/rendering/pdf_preprocess.py" "$preprocessed_html" \
        "--resource-path=$(dirname "$source_path")" --metadata "title= "

    weasyprint "$preprocessed_html" "$destination_pdf" 2>/dev/null
    local size display_path
    size="$(du -k "$destination_pdf" 2>/dev/null | cut -f1)"
    display_path="${destination_pdf##*/PDFs/}"
    echo "  ✓ ${display_path} (${size} KiB)"
    rm -f "$preprocessed_html"
}

# Collect generated artifacts into /output (if mounted).
# Builds already write under $WORKSPACE/output, which is typically the same
# bind mount as /output. Sync only when the two paths differ.
collect_outputs() {
    [[ -d "$OUTPUT" ]] || return 0

    bold "Collecting outputs to output/..."

    local ws_out="$WORKSPACE/output"
    if [[ ! -d "$ws_out" ]]; then
        yellow "No workspace output/ directory to collect."
        return 0
    fi

    # /workspace/output and /output are often the same host dir bind-mounted twice.
    if [[ "$ws_out" -ef "$OUTPUT" ]]; then
        green "Outputs already under output/ (same mount as /output)."
        return 0
    fi

    mkdir -p "$OUTPUT"
    cp -a "$ws_out"/. "$OUTPUT"/
    green "Outputs synced to /output from workspace/output/"
}

SKIP_COLLECT=false

# ── Commands ─────────────────────────────────────────────────────────

cmd_setup() {
    local client="${1:-}"
    if [[ -z "$client" ]]; then
        red "Error: client name is required."
        echo "Usage: make setup CLIENT=\"Your Client Name\" PROJECT=\"HC\" [FORCE=1]"
        exit 1
    fi
    shift
    local project_code="HC"
    if [[ $# -gt 0 && "${1:-}" != --* ]]; then
        project_code="$1"
        shift
    fi
    if [[ "${SETUP_FORCE:-}" == "1" ]]; then
        set -- "$@" --force
    fi
    bold "=== Setting up project for: ${client} (${project_code}) ==="
    python3 "/workspace/scripts/setup_project.py" "$WORKSPACE" "$client" "$project_code" "$@"
    green "Setup complete."
}

cmd_status() {
    python3 "/workspace/scripts/setup_project.py" "$WORKSPACE" --status
}

_hc_draft_each_report() {
    local generate_log="$1"
    export HC_CURSOR_PYTHON="${HC_CURSOR_PYTHON:-/usr/bin/python3}"
    export PYTHONPATH="$WORKSPACE/scripts/shared/rendering:$WORKSPACE/scripts/health_check:$WORKSPACE/scripts/shared/lib:/toolkit/health_check:/toolkit/shared/lib:${PYTHONPATH:-}"
    local report_path
    local found=0
    while IFS= read -r report_path; do
        [[ -n "$report_path" ]] || continue
        found=1
        python3 "$WORKSPACE/scripts/health_check/draft_summary_conclusion.py" \
            --in-place "$report_path" \
            --tool "${AI_TOOL:-cursor}"
    done < <(
        python3 -c "
from pathlib import Path
import sys
sys.path.insert(0, '/workspace/scripts/shared/rendering')
from hc_export_paths import draft_targets_from_generate_log
for path in draft_targets_from_generate_log(Path(sys.argv[1]).read_text(encoding='utf-8')):
    print(path)
" "$generate_log"
    )
    if [[ "$found" -eq 0 ]]; then
        red "Error: generate_report wrote no report markdown this run; refusing to draft other files."
        exit 1
    fi
}

cmd_hc_report() {
    bold "=== Generating Health Check Report ==="
    export PYTHONPATH="$WORKSPACE/scripts/health_check:$WORKSPACE/scripts/shared/lib:/toolkit/health_check:/toolkit/shared/lib:${PYTHONPATH:-}"
    local generate_log
    generate_log="$(mktemp)"
    if ! python3 -u /toolkit/health_check/generate_report.py "$@" | tee "$generate_log"; then
        rm -f "$generate_log"
        exit 1
    fi
    if [[ "${HC_SUMMARY_CONCLUSION:-}" == "1" ]]; then
        bold "=== Drafting Chapter 3 and Chapter 8 (opt-in) ==="
        _hc_draft_each_report "$generate_log"
    fi
    rm -f "$generate_log"
    collect_outputs
    green "Health Check report complete."
}

cmd_hc_summary_conclusion() {
    local report_path="${1:-}"
    if [[ -z "$report_path" || ! -f "$report_path" ]]; then
        red "Error: report markdown not found: ${report_path:-<missing>}"
        echo "Usage: hc-summary-conclusion /workspace/output/Health_Check_Report/<report>.md"
        exit 1
    fi
    bold "=== Drafting Chapter 3 and Chapter 8 in place ==="
    export HC_CURSOR_PYTHON="${HC_CURSOR_PYTHON:-/usr/bin/python3}"
    export PYTHONPATH="$WORKSPACE/scripts/health_check:$WORKSPACE/scripts/shared/lib:/toolkit/health_check:/toolkit/shared/lib:${PYTHONPATH:-}"
    python3 "$WORKSPACE/scripts/health_check/draft_summary_conclusion.py" \
        --in-place "$report_path" \
        --tool "${AI_TOOL:-cursor}"
    green "In-place draft complete."
}

cmd_hc_update_loi() {
    local report_path="${1:-}"
    local dry_run_flag="${2:-}"
    if [[ -z "$report_path" || ! -f "$report_path" ]]; then
        red "Error: report markdown not found: ${report_path:-<missing>}"
        echo "Usage: hc-update-loi /workspace/output/Health_Check_Report/<report>.md [--dry-run]"
        exit 1
    fi
    export PYTHONPATH="$WORKSPACE/scripts/health_check:$WORKSPACE/scripts/shared/lib:/toolkit/health_check:/toolkit/shared/lib:${PYTHONPATH:-}"
    bold "=== Refreshing Chapter 6 Level of Impact from KB ==="
    if [[ "$dry_run_flag" == "--dry-run" ]]; then
        python3 "$WORKSPACE/scripts/health_check/update_finding_loi.py" --dry-run "$report_path"
    else
        python3 "$WORKSPACE/scripts/health_check/update_finding_loi.py" --in-place "$report_path"
    fi
}

cmd_hc_renumber_findings() {
    local report_path="${1:-}"
    local dry_run_flag="${2:-}"
    if [[ -z "$report_path" || ! -f "$report_path" ]]; then
        red "Error: report markdown not found: ${report_path:-<missing>}"
        echo "Usage: hc-renumber-findings /workspace/output/Health_Check_Report/<report>.md [--dry-run]"
        exit 1
    fi
    export PYTHONPATH="$WORKSPACE/scripts/health_check:$WORKSPACE/scripts/shared/lib:/toolkit/health_check:/toolkit/shared/lib:${PYTHONPATH:-}"
    bold "=== Resequencing Chapter 6 finding numbers ==="
    if [[ "$dry_run_flag" == "--dry-run" ]]; then
        python3 "$WORKSPACE/scripts/health_check/renumber_finding_sections.py" --dry-run "$report_path"
    else
        python3 "$WORKSPACE/scripts/health_check/renumber_finding_sections.py" "$report_path"
    fi
}

cmd_hc_investigate() {
    bold "=== Investigating Health Check finding ==="
    export PYTHONPATH="$WORKSPACE/scripts/health_check:$WORKSPACE/scripts/shared/lib:/toolkit/health_check:/toolkit/shared/lib:${PYTHONPATH:-}"
    python3 /toolkit/health_check/hc_investigate.py "$@"
}

_hc_overwrite_is_allowed() {
    if [[ "${HC_EXPORT_FORCE:-}" == "1" ]]; then
        return 0
    fi
    if [[ ! -t 0 ]]; then
        return 1
    fi
    local overwrite_reply=""
    echo "========================================================================" >&2
    echo "WARNING: OVERWRITE EXISTING EXPORT" >&2
    echo "========================================================================" >&2
    echo "The destination HTML or PDF already exists." >&2
    echo "Overwrite existing export? [y/N]" >&2
    set +e
    read -r overwrite_reply
    set -e
    overwrite_reply="$(printf '%s' "${overwrite_reply:-}" | tr '[:upper:]' '[:lower:]')"
    [[ "$overwrite_reply" == "y" || "$overwrite_reply" == "yes" ]]
}

run_hc_export_mapping() {
    local report_dir="$1"
    local export_root="$2"
    local extension="$3"
    local named_source="$4"
    local mapping_file="$5"
    local extra=()
    local mapping_status
    if [[ -n "$named_source" ]]; then
        extra+=(--source "$named_source")
    fi

    _run_export_paths() {
        python3 /workspace/scripts/shared/rendering/hc_export_paths.py \
            "$report_dir" "$export_root" "$extension" "${extra[@]}" \
            > "$mapping_file"
    }

    set +e
    _run_export_paths
    mapping_status=$?
    set -e
    if [[ "$mapping_status" -eq 0 ]]; then
        return 0
    fi
    if [[ "$mapping_status" -ne 4 ]]; then
        return "$mapping_status"
    fi
    if ! _hc_overwrite_is_allowed; then
        red "Error: destination exists. Re-run with FORCE=1 to overwrite."
        return 1
    fi
    extra+=(--allow-overwrite)
    _run_export_paths
}

cmd_hc_html() {
    require_project_yaml
    bold "=== Generating Health Check HTML Report ==="
    echo ""

    local report_dir="$WORKSPACE/output/Health_Check_Report"
    local html_dir="${report_dir}/HTML"
    local named_source="${1:-}"

    mkdir -p "$html_dir"

    local css_file mapping_file
    css_file="$(mktemp --suffix=.css)"
    mapping_file="$(mktemp)"
    python3 /workspace/scripts/shared/lib/config.py render-css-html > "$css_file"

    if ! run_hc_export_mapping "$report_dir" "$html_dir" html \
        "$named_source" "$mapping_file"; then
        rm -f "$css_file" "$mapping_file"
        exit 1
    fi

    local source_markdown destination_html
    while IFS=$'\t' read -r source_markdown destination_html; do
        [[ -n "$source_markdown" ]] || continue
        mkdir -p "$(dirname "$destination_html")"
        # Blank title matches PDF: do not emit the markdown stem as a page heading.
        _render_md_to_html "$source_markdown" "$css_file" \
            "/workspace/scripts/shared/rendering/html_collapsible.py" "$destination_html" \
            --metadata "title= "
    done < "$mapping_file"

    rm -f "$css_file" "$mapping_file"
    green "HTML report → output/Health_Check_Report/HTML/"
}

cmd_hc_pdf() {
    require_project_yaml
    bold "=== Generating Health Check PDFs ==="
    echo ""

    local report_dir="$WORKSPACE/output/Health_Check_Report"
    local named_source="${1:-}"

    mkdir -p "$report_dir/PDFs"

    local css_file mapping_file
    css_file="$(mktemp --suffix=.css)"
    mapping_file="$(mktemp)"
    python3 /workspace/scripts/shared/lib/config.py render-css --doc-type hc > "$css_file"

    if ! run_hc_export_mapping "$report_dir" "$report_dir/PDFs" pdf \
        "$named_source" "$mapping_file"; then
        rm -f "$css_file" "$mapping_file"
        exit 1
    fi

    local source_markdown destination_pdf
    while IFS=$'\t' read -r source_markdown destination_pdf; do
        [[ -n "$source_markdown" ]] || continue
        mkdir -p "$(dirname "$destination_pdf")"
        _convert_md_to_pdf "$source_markdown" "$destination_pdf" "$css_file"
    done < "$mapping_file"

    rm -f "$css_file" "$mapping_file"
    green "Health Check PDF generation complete."
}

cmd_help() {
    bold "Red Hat health checks (container)"
    echo ""
    echo "  setup <client>         First-time project setup"
    echo "  hc-report              Generate a report from collected data"
    echo "  hc-summary-conclusion  Draft Chapter 3/8 into an existing report"
    echo "  hc-update-loi          Refresh Chapter 6 Level of Impact from KB TOML"
    echo "  hc-renumber-findings   Resequence section 6.2 finding IDs"
    echo "  hc-html [path]         Generate collapsible HTML"
    echo "  hc-pdf [path]          Generate a branded PDF"
    echo "  hc-investigate         Trace a finding to raw evidence"
    echo "  status                 Show project readiness"
    echo "  help                   Show this message"
    echo ""
    echo "Normally invoked via the Makefile: make setup CLIENT=\"Example Client\" PROJECT=\"HC\""
}

# ── Router ───────────────────────────────────────────────────────────

case "${1:-help}" in
    setup)      shift; cmd_setup "$@" ;;
    hc-report)  shift; cmd_hc_report "$@" ;;
    hc-summary-conclusion) shift; cmd_hc_summary_conclusion "$@" ;;
    hc-update-loi) shift; cmd_hc_update_loi "$@" ;;
    hc-renumber-findings) shift; cmd_hc_renumber_findings "$@" ;;
    hc-html)    shift; cmd_hc_html "$@" ;;
    hc-pdf)     shift; cmd_hc_pdf "$@" ;;
    hc-investigate) shift; cmd_hc_investigate "$@" ;;
    status)     cmd_status ;;
    help|--help|-h) cmd_help ;;
    *)          red "Unknown command: $1"; cmd_help; exit 1 ;;
esac
