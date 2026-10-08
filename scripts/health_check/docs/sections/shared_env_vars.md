KUBECONFIG          Path to kubeconfig (live cluster collection)
HC_COLLECT_OUT      output/hc_collect        — collection results directory
HC_REPORT_OUT       output/Health_Check_Report — final report output
HC_SSH_HOST         user@host                — remote support shell server
HC_SSH_RESULTS      results path on remote (default is the current well-known stem
                    ~/hc_results, but ~ does not resolve reliably here — set
                    explicitly, e.g. /home/remote/<username>/hc_results). Set to
                    /home/remote/<username>/hc_results.<cluster> to fetch a salvage tarball
HC_SSH_SCRIPTS      scripts path on remote (default is ~/hc_supportshell — same ~
                    caveat, set explicitly, e.g. /home/remote/<username>/hc_supportshell)
HC_MG_INPUT         must-gather/case path on remote (for hc-collect-remote) — always set
                    explicitly, e.g. /home/remote/<username>/<case-number>, not ~/<case-number>
HC_FETCH_STAGE      output/hc_collect/<date> — dated staging dir for supportshell fetches (auto-computed)
MERGE_INPUTS        "dir1 dir2 ..."          — inputs for hc-merge
HC_TSR_HTML         repo-relative path to a TSR HTML export (overrides auto-discovery)
HC_TSR_HTML_DIR     output/tsr_html          — directory for TSR HTML auto-discovery (default)
HC_CHECK_PROFILE    advisory                 — check expansion profile: core | extended | advisory
HC_OMIT_CHECK_IDS   repo-relative path to a check-ID omit list (writes {stem}_pruned.md)
HC_OMIT_STRICT      1                        — fail if an omit ID is not on a Chapter 6 finding
HC_CCX_RULES_FILE   /path/to/ccx_rules.json — optional CCX runtime payload for collection
HC_DOCS_ROOT        local OpenShift docs tree for make hc-link-review
HC_LINK_REVIEW_OUT  output dir for kb_link_review.md / .csv
ENGINE              podman or docker (podman when it is on PATH)
IMAGE               redhat-health-checks     — container image name
CLIENT              client name for make setup
PROJECT             HC                       — engagement code (default)
FORCE               1 to replace files setup already created, or overwrite an hc-html/hc-pdf basename dest
REPORT              one markdown file for hc-html, hc-pdf, hc-summary-conclusion, hc-update-loi, hc-renumber-findings
DRY_RUN             1 to preview hc-update-loi or hc-renumber-findings
HC_DRY_RUN          1 to pass --dry-run on hc-report (placeholder executive summary)
HC_SUMMARY_CONCLUSION  1 to draft Chapter 3 and Chapter 8 after hc-report
RESULTS_DIR         collected JSON directory for hc-investigate
FINDING_ID          finding id for hc-investigate (CHECK_ID= or QUERY= also work)
LEDGER              skipped_commands.jsonl path for hc-skip-summary (RESULTS_DIR= also works)
TSR_HTML            TSR HTML export for make hc-build-catalog
AI_TOOL             optional tool name passed into the Chapter 3/8 draft
