# Knowledge base

## Purpose

Normative consultant prose and finding flags for every `[[checks]]` row on `main`. The report engine renders these rows. It does not execute the `oc` snippets inside `verification`. Scoring status is `hc-native-scoring` and `hc-report-engine`, not this file.

## Requirements

### Requirement: Knowledge-base files
The loader SHALL read `scripts/health_check/hc_report/kb/7_1_base_platform.toml` through `7_9_hardware.toml` plus `versions.toml`. `active_versions` SHALL be 4.18, 4.19, 4.20, 4.21, and 4.22. The Red Hat doc base URL SHALL be `https://docs.redhat.com/en/documentation/openshift_container_platform`. Lookup SHALL prefer an exact `check_id`, then the first `pattern = true` glob. A missing recommendation SHALL render `[NEEDS REVIEW]`. `content_from` SHALL copy inherited prose in one hop and SHALL raise `ValueError` on overlay, chains, self-reference, a missing target, or a pattern target. Inherited fields are recommendation, verification, description, impact, impact_scope, impact_detail, links, recommendation_supported_versions, priority_hint, and summary_patterns. Title and finding flags stay on the alias.

#### Scenario: Exact id wins over a glob
- GIVEN an exact row and a pattern row that would also match
- WHEN `get_entry` is called with the exact id
- THEN the exact row is returned

#### Scenario: Active versions
- GIVEN `versions.toml`
- WHEN the knowledge base loads
- THEN active versions are 4.18 through 4.22 inclusive


### Requirement: KB 7.1.sub.*
`load_kb()` SHALL contain `7.1.sub.*` from `7_1_base_platform.toml`. Title SHALL be `Operator subscription health`.

The row SHALL be a glob pattern.

description SHALL be:

A Subscription tracks the desired channel and installed/current CSV for an
installed operator. Non-`AtLatestKnown` states, pending upgrades, or failed CSVs
indicate the operator lifecycle needs attention before it drifts further from
the intended state.

recommendation SHALL be:

Review every Operator Subscription that is not in the expected `AtLatestKnown` state or whose installed CSV does not match the current CSV, then determine whether the difference is intentional or requires remediation. For a pending manual `InstallPlan`, review the operator release notes, compatibility requirements, and change window before approving it. For a failed or pending CSV, inspect its status, related events, catalog-source health, dependencies, and `InstallPlan` errors before making changes.

verification SHALL be:

1. List the Subscription object in the operator namespace:
   `oc get subscription <name> -n <ns> -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CHANNEL:.spec.channel,STATE:.status.state,INSTALLED:.status.installedCSV,CURRENT:.status.currentCSV`
2. Healthy is **PASS** when STATE is `AtLatestKnown` and INSTALLED matches CURRENT:
   `oc get subscription <name> -n <ns> --no-headers -o custom-columns=STATE:.status.state,INSTALLED:.status.installedCSV,CURRENT:.status.currentCSV | awk '{print ($1=="AtLatestKnown" && $2==$3?"PASS":"FAIL"), $0}'`
3. Print the Subscription conditions:
   `oc get subscription <name> -n <ns> -o jsonpath='{range .status.conditions[*]}{.type}={.status} reason={.reason}{"\n"}{end}'`
4. If the subscription is not healthy, check `InstallPlan` approval and phase:
   `oc get installplan -n <ns> -o custom-columns=NAME:.metadata.name,CSV:.spec.clusterServiceVersionNames,APPROVED:.spec.approved,PHASE:.status.phase`
5. For a pending manual `InstallPlan`, review release notes then approve:
   `oc patch installplan <name> -n <ns> --type=merge -p '{"spec":{"approved":true}}'`
6. For a failed CSV, describe it for events and status:
   `oc describe csv <csv-name> -n <ns>`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

affected operator namespace

impact_detail SHALL be:

Approving an `InstallPlan` or adjusting a Subscription does not reboot nodes, but it can roll the operator deployment and trigger managed-component reconciliation.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`.

#### Scenario: 7.1.sub.* loads
- WHEN `get_entry` is called with `7.1.sub.*`
- THEN the title is `Operator subscription health`
- AND `content_from` is empty


### Requirement: KB 7.1.clusterversion.channel
`load_kb()` SHALL contain `7.1.clusterversion.channel` from `7_1_base_platform.toml`. Title SHALL be `Update channel`.

description SHALL be:

The update channel selects which OCP releases the Cluster Version Operator offers.
`fast` and `stable` are both fully supported; the only documented difference is
promotion delay (typically a week or two for z-stream, often 45-90 days for a
new minor). `eus` channels allow skipping minor versions on supported EUS paths.
`candidate` is unsupported early access.

recommendation SHALL be:

Put production on `stable` or `eus` to match the support policy. Move off `candidate`; it is unsupported. Leave fast only if the shorter promotion delay is an accepted operational choice. Do not patch until the running release exists in the target channel.

verification SHALL be:

1. List the current channel and available updates:
   `oc adm upgrade`
2. Confirm the running release exists in the target `stable-X.Y` or `eus-X.Y` channel before switching.
3. If a channel change is needed, patch the `ClusterVersion` object (`version`):
   `oc patch clusterversion version --type=merge -p '{"spec":{"channel":"stable-<minor>"}}'`
4. Re-check `availableUpdates` and `conditionalUpdates`. `fast` is a supported channel with shorter promotion delay.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

cluster update service

impact_detail SHALL be:

Changing the update channel does not restart nodes or workloads; it only changes which releases the Cluster Version Operator offers.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#fast-stable-channel-strategies_understanding-update-channels-releases`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#fast-stable-channel-strategies_understanding-update-channels-releases`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#fast-stable-channel-strategies_understanding-update-channels-releases`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#fast-stable-channel-strategies_understanding-update-channels-releases`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#fast-stable-channel-strategies_understanding-update-channels-releases`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#fast-stable-channel-strategies_understanding-update-channels-releases`.

#### Scenario: 7.1.clusterversion.channel loads
- WHEN `get_entry` is called with `7.1.clusterversion.channel`
- THEN the title is `Update channel`
- AND `content_from` is empty


### Requirement: KB 7.1.clusterversion.updates
`load_kb()` SHALL contain `7.1.clusterversion.updates` from `7_1_base_platform.toml`. Title SHALL be `Available updates`.

description SHALL be:

The Cluster Version Operator (CVO) lists supported upgrade targets in status.availableUpdates. The presence of available updates is a lifecycle-management indicator rather than a cluster health failure. Review the recommended update path, assess release notes and compatibility requirements, and schedule the upgrade within an appropriate maintenance window.

recommendation SHALL be:

Schedule a maintenance window to apply a recommended update shown in the OpenShift upgrade graph. Select an approved z-stream or minor-version target, follow only the upgrade paths offered by the graph.

verification SHALL be:

1. Print the cluster version, channel, and available updates:
   `oc get clusterversion version -o jsonpath='{.status.desired.version}{" "}{.spec.channel}{"\n"}{range .status.availableUpdates[*]}available={.version}{"\n"}{end}'`
   `oc adm upgrade`
2. Check the supported upgrade path using the OCP Upgrade Graph at https://access.redhat.com/labs/ocpupgradegraph/.
3. After validating the path in a non-production cluster, apply the chosen release:
   `oc adm upgrade --to=<target-version>`
4. Monitor the ClusterVersion conditions until the rollout completes:
   `oc get clusterversion version -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster-wide

impact_detail SHALL be:

Minor or z-stream upgrades reconcile cluster operators and can drain, reboot, or roll nodes and workloads over time.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#upgrade-version-paths_understanding-update-channels-releases`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#upgrade-version-paths_understanding-update-channels-releases`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#upgrade-version-paths_understanding-update-channels-releases`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#upgrade-version-paths_understanding-update-channels-releases`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#upgrade-version-paths_understanding-update-channels-releases`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#upgrade-version-paths_understanding-update-channels-releases`.

#### Scenario: 7.1.clusterversion.updates loads
- WHEN `get_entry` is called with `7.1.clusterversion.updates`
- THEN the title is `Available updates`
- AND `content_from` is empty


### Requirement: KB 7.1.infra.topology
`load_kb()` SHALL contain `7.1.infra.topology` from `7_1_base_platform.toml`. Title SHALL be `Infrastructure topology`.

description SHALL be:

Highly Available topology requires at least 3 control plane nodes and ensures
loss of any single node does not cause an outage. SingleReplica topology is
supported only for edge or test-style deployments.

recommendation SHALL be:

Run production as HighlyAvailable with at least three Ready masters unless this is documented SNO or edge. If topology is undersized for the intended use, plan a supported control-plane migration or rebuild. Do not toggle topology fields in place.

verification SHALL be:

1. Print the control-plane and infrastructure topology from the Infrastructure object:
   `oc get infrastructure cluster -o jsonpath='{.status.controlPlaneTopology}{"\t"}{.status.infrastructureTopology}{"\n"}'`
2. Confirm the control-plane node count matches the topology:
   `oc get nodes -l node-role.kubernetes.io/master --no-headers`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and infrastructure architecture

impact_detail SHALL be:

Moving from non-HA to HA usually requires control-plane or infrastructure machine changes, not a simple in-place toggle, and should be planned as a migration.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#about-control-planes_architecture-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#about-control-planes_architecture-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#about-control-planes_architecture-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#about-control-planes_architecture-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#about-control-planes_architecture-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#about-control-planes_architecture-overview`.

#### Scenario: 7.1.infra.topology loads
- WHEN `get_entry` is called with `7.1.infra.topology`
- THEN the title is `Infrastructure topology`
- AND `content_from` is empty


### Requirement: KB 7.1.subs.approval
`load_kb()` SHALL contain `7.1.subs.approval` from `7_1_base_platform.toml`. Title SHALL be `Subscription approval policy`.

description SHALL be:

Automatic `installPlanApproval` causes operators to upgrade automatically when
new versions are available in the channel. This can introduce breaking changes
without notice. Use Manual approval and review release notes before upgrades.

recommendation SHALL be:

Set production subscriptions to Manual unless the install method requires Automatic (STS or workload identity). OpenShift Virtualization `kubevirt-hyperconverged` Automatic is not a WARNING. Patch other Automatic subscriptions to Manual and approve pending `InstallPlan`s only in planned windows.

verification SHALL be:

1. List the Subscription approval policy per namespace:
   `oc get subscription -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,APPROVAL:.spec.installPlanApproval,STATE:.status.state`
2. To switch a subscription to `Manual` approval:
   `oc patch subscription <name> -n <ns> --type=merge -p '{"spec":{"installPlanApproval":"Manual"}}'`
3. Automatic is also a supported policy, required in some cases such as STS or workload-identity installs.
4. List pending `InstallPlan`s:
   `oc get installplan -A`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

affected operator namespace

impact_detail SHALL be:

Changing `installPlanApproval` updates Subscription behavior immediately without rebooting nodes or evicting workloads.

`finding_group` SHALL be `operator-approval`.

`finding_group_title` SHALL be `Operator subscription installPlanApproval`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/operators/index#olm-installplan_olm-understanding-olm`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/operators/index#olm-installplan_olm-understanding-olm`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/operators/index#olm-installplan_olm-understanding-olm`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/operators/index#olm-installplan_olm-understanding-olm`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/operators/index#olm-installplan_olm-understanding-olm`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/operators/index#olm-installplan_olm-understanding-olm`.

#### Scenario: 7.1.subs.approval loads
- WHEN `get_entry` is called with `7.1.subs.approval`
- THEN the title is `Subscription approval policy`
- AND `content_from` is empty


### Requirement: KB 7.1.sys.firewall
`load_kb()` SHALL contain `7.1.sys.firewall` from `7_1_base_platform.toml`. Title SHALL be `Firewall configuration`.

description SHALL be:

A cluster-wide proxy (`httpProxy` or `httpsProxy`) implies extra allow-list, noProxy,
and firewall work. Presence of those fields is a warning to review egress paths. This
does not probe host iptables or security-group ports.

recommendation SHALL be:

Where a cluster-wide proxy is configured, validate that the proxy, noProxy entries, DNS, firewall rules, and outbound allow-lists support all required OpenShift control-plane and platform egress paths. Ensure internal destinations bypass the proxy—including cluster, service, and machine-network CIDRs, .svc and .cluster.local domains, and the internal API endpoint so node-to-node and in-cluster traffic is not incorrectly proxied. Confirm that the proxy or egress firewall permits required external endpoints such as registries, Red Hat services, cloud-provider APIs, and any organization-specific dependencies.

verification SHALL be:

1. Print the cluster-wide proxy settings:
   `oc get proxy cluster -o jsonpath='{.spec.httpProxy}{"\t"}{.spec.httpsProxy}{"\t"}{.spec.noProxy}{"\n"}'`
2. If a proxy is set, confirm that `noProxy` includes cluster, service, and machine CIDRs plus internal API and .cluster.local.
3. Print the CNI plugin name (for example `OVNKubernetes`):
   `oc get network.config cluster -o jsonpath='{.spec.networkType}'`
4. Confirm the overlay port for that plugin is allowed between nodes:
      - OVNKubernetes: Geneve UDP 6081
      - OpenShiftSDN (removed in 4.17): VXLAN UDP 4789
      Common to all: API 6443, etcd peer 2380, kubelet 10250, NodePort 30000-32767.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

affected nodes and external network controls

impact_detail SHALL be:

Security-group or ACL changes can be live, but host-firewall changes may briefly interrupt traffic and can require coordinated node-level rollout.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`.

#### Scenario: 7.1.sys.firewall loads
- WHEN `get_entry` is called with `7.1.sys.firewall`
- THEN the title is `Firewall configuration`
- AND `content_from` is empty


### Requirement: KB 7.1.sys.auth
`load_kb()` SHALL contain `7.1.sys.auth` from `7_1_base_platform.toml`. Title SHALL be `Authentication configuration`.

description SHALL be:

Cluster authentication determines how users and service accounts authenticate.
The default kubeadmin user should be removed after external identity providers
are configured and validated.

recommendation SHALL be:

Configure an external identity provider (LDAP, OIDC, or SAML), validate login, and only then remove kubeadmin. Document emergency access. Do not delete kubeadmin until that login works.

verification SHALL be:

1. List the configured identity providers on the OAuth object:
   `oc get oauth cluster -o jsonpath='{.spec.identityProviders[*].name}{"\t"}{.spec.identityProviders[*].type}{"\n"}'`
2. HTPasswd alone is a weak production IdP. LDAP, OIDC, or SAML should be configured and tested before removing kubeadmin.
3. Confirm break-glass emergency access is documented in case the identity provider becomes unavailable.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

authentication components

impact_detail SHALL be:

Editing the cluster OAuth configuration rolls authentication pods and can briefly affect user logins, but it does not reboot nodes or stop running workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/authentication_and_authorization/index#configuring-identity-providers`.

#### Scenario: 7.1.sys.auth loads
- WHEN `get_entry` is called with `7.1.sys.auth`
- THEN the title is `Authentication configuration`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_2_3_dns_alerts
`load_kb()` SHALL contain `7.1.tsr.1_5_2_3_dns_alerts` from `7_1_base_platform.toml`. Title SHALL be `TSR DNS alerts`.

description SHALL be:

DNS-related alerts indicate resolution failures that can cascade into pod
scheduling issues, service discovery failures, and operator degradation. DNS
is a foundational cluster service — any degradation must be resolved promptly.

recommendation SHALL be:

Clear firing CoreDNSErrorsHigh, CoreDNSHealthCheckSlow, and CoreDNSPanicking. Fix the DNS instance that matches the alert name. Empty Prometheus output means none of those alerts are firing. Ignore Thanos DNS alert names. Fix forwarding and listen-port issues on their own rows, not by silencing these alerts.

verification SHALL be:

1. List the CoreDNS alerting rules from the PrometheusRule in openshift-dns-operator:
   `oc get prometheusrule dns -n openshift-dns-operator -o jsonpath='{range .spec.groups[*].rules[?(@.alert)]}{.alert}{"\n"}{end}'`
      The DNS Operator ships `CoreDNSErrorsHigh`, `CoreDNSHealthCheckSlow`, and `CoreDNSPanicking`.
2. Check which of those are currently firing:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname | test("^CoreDNS")) | {state, alertname: .labels.alertname, severity: .labels.severity}'`
3. Investigate by alert name:
      - `CoreDNSErrorsHigh`: SERVFAIL share >1 % for 5 min. Inspect DNS logs:
     `oc -n openshift-dns logs -l dns.operator.openshift.io/daemonset-dns --tail=100`
      - `CoreDNSHealthCheckSlow`: health-check p95 >10 s. Check DNS pod readiness and restarts:
     `oc get pods -n openshift-dns`
      - `CoreDNSPanicking`: panics in 10 min. Check the same logs, then describe the crashing pod:
     `oc describe pod <name> -n openshift-dns`

impact SHALL be:

workload-shift

impact_scope SHALL be:

CoreDNS pods and cluster name resolution

impact_detail SHALL be:

Restoring dns.operator default rolls CoreDNS and can briefly break name resolution. It does not reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_operators/index#nw-dns-operator_dns-operator`.

#### Scenario: 7.1.tsr.1_5_2_3_dns_alerts loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_2_3_dns_alerts`
- THEN the title is `TSR DNS alerts`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.openshift_must_gather_collection
`load_kb()` SHALL contain `7.1.tsr.openshift_must_gather_collection` from `7_1_base_platform.toml`. Title SHALL be `OpenShift Must Gather Collection`.

description SHALL be:

Must-gather captures cluster-wide diagnostic data including logs, resource
definitions, and event histories. Verifying collection success ensures
downstream analysis has complete data to work with.

recommendation SHALL be:

Produce a complete must-gather tarball with no collection errors before analysis. Re-run on a live cluster if the capture failed. If you only have a partial archive, record the gap and stop.

verification SHALL be:

1. Collect cluster diagnostics:
   `oc adm must-gather`
2. Confirm the output tarball was created without errors.
3. Review the must-gather logs for collection errors or timeouts that indicate incomplete data.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#about-must-gather_gathering-cluster-data`.

#### Scenario: 7.1.tsr.openshift_must_gather_collection loads
- WHEN `get_entry` is called with `7.1.tsr.openshift_must_gather_collection`
- THEN the title is `OpenShift Must Gather Collection`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.openshift_must_gather_data_capture_timestamps
`load_kb()` SHALL contain `7.1.tsr.openshift_must_gather_data_capture_timestamps` from `7_1_base_platform.toml`. Title SHALL be `OpenShift Must Gather Data Capture Timestamps`.

description SHALL be:

Timestamps within must-gather data indicate when diagnostic information was
collected. Stale or mismatched timestamps may indicate partial captures or
time-skew issues that reduce diagnostic accuracy.

recommendation SHALL be:

Use a capture window that covers the incident. Re-run must-gather with live access if hours of spread or a capture older than the incident miss the window. If timestamps look impossible, fix node clocks first.

verification SHALL be:

1. Read the must-gather capture-start file. It is one RFC3339 UTC line named `timestamp` in the image directory that also contains `cluster-scoped-resources/` and `namespaces/`. It is not object `metadata.creationTimestamp`:
   `cat <must-gather-image-dir>/timestamp`
2. Compare every `timestamp` file in that tree to assess spread:
   `find <must-gather-image-dir> -name timestamp -exec grep -H . {} \;`
      Minutes of spread is a long collection. Hours of spread or a capture older than the incident means the wrong window or clock skew.
3. If this engagement used live `hc-collect` instead of a must-gather, check the collect timestamps:
   `jq -r .timestamp <results-dir>/manifest.json`
   `find <results-dir> -name '*.meta.json' -exec jq -r .timestamp {} \; | sort | sed -n '1p;$p'`
4. If the capture window misses the incident, re-run with live cluster access: `oc adm must-gather`. If you only have the tarball, record the window and stop.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#about-must-gather_gathering-cluster-data`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#about-must-gather_gathering-cluster-data`.

#### Scenario: 7.1.tsr.openshift_must_gather_data_capture_timestamps loads
- WHEN `get_entry` is called with `7.1.tsr.openshift_must_gather_data_capture_timestamps`
- THEN the title is `OpenShift Must Gather Data Capture Timestamps`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_1_identification_and_state
`load_kb()` SHALL contain `7.1.tsr.1_1_identification_and_state` from `7_1_base_platform.toml`. Title SHALL be `1.1. Identification and State`.

description SHALL be:

This check records the installed OpenShift Container Platform version and its Red Hat support lifecycle status, such as **Full Support**, **Maintenance Support**, or end of life. Lifecycle status is a planning and supportability indicator; it does not by itself mean that a ClusterOperator is degraded or that the cluster is unhealthy.

recommendation SHALL be:

If the cluster is in **Maintenance Support** or has reached end of life, plan and schedule an upgrade through a supported upgrade path. Continue to assess unhealthy ClusterOperators in their respective health checks, since lifecycle classification alone is not an operator failure.

verification SHALL be:

1. Print the version and channel from the ClusterVersion object:
   `oc get clusterversion version -o jsonpath='{.status.desired.version}{" "}{.spec.channel}{"\n"}'`
   `oc adm upgrade`
2. Compare that version to the OpenShift Container Platform life-cycle dates at:
      https://access.redhat.com/support/policy/updates/openshift
      That page classifies the release as fully supported, maintenance, or EOL. `oc get co` does not show lifecycle status.
3. ClusterOperator Degraded or Progressing is a separate issue. To list only unhealthy operators:
   `oc get co | grep -v 'True.*False.*False'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster-wide

impact_detail SHALL be:

Addressing stale upgrade history usually means performing a cluster upgrade, which rolls operators, nodes, and workloads over time.

Links SHALL be `default` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.18` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.19` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.20` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.21` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.22` -> `https://access.redhat.com/support/policy/updates/openshift`.

#### Scenario: 7.1.tsr.1_1_identification_and_state loads
- WHEN `get_entry` is called with `7.1.tsr.1_1_identification_and_state`
- THEN the title is `1.1. Identification and State`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_2_subscriptions
`load_kb()` SHALL contain `7.1.tsr.1_2_subscriptions` from `7_1_base_platform.toml`. Title SHALL be `1.2. Subscriptions`.

description SHALL be:

Operator subscriptions track installed operators, their channels, and update
policies. Unhealthy subscriptions lead to stale operator versions, failed
CSVs, and degraded cluster capabilities.

recommendation SHALL be:

Get every subscription to `AtLatestKnown` with INSTALLED equal to CURRENT. If STATE differs or CSVs do not match, inspect `InstallPlan` approval and CSV phase.

verification SHALL be:

1. List all Subscriptions and the fields this check evaluates:
   `oc get subscription -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CHANNEL:.spec.channel,STATE:.status.state,INSTALLED:.status.installedCSV,CURRENT:.status.currentCSV`
2. Healthy is **PASS** when `STATE=AtLatestKnown` and `INSTALLED` equals `CURRENT`. A mismatch means an upgrade is pending.
3. Check `InstallPlan` phase and approval to find where a pending upgrade is stuck:
   `oc get installplan -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CSV:.spec.clusterServiceVersionNames,APPROVED:.spec.approved,PHASE:.status.phase`
4. List CSV phase. A `Failed` phase is **FAIL**; describe that CSV for details:
   `oc get csv -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase`
   `oc describe csv <csv-name> -n <ns>`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

operator namespaces and InstallPlans

impact_detail SHALL be:

Repairing a stuck Subscription or CSV rolls that operator. It does not reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/operators/index#olm-status-viewing-cli_olm-troubleshooting-operator-issues`.

#### Scenario: 7.1.tsr.1_2_subscriptions loads
- WHEN `get_entry` is called with `7.1.tsr.1_2_subscriptions`
- THEN the title is `1.2. Subscriptions`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_3_infrastructure_requirements
`load_kb()` SHALL contain `7.1.tsr.1_3_infrastructure_requirements` from `7_1_base_platform.toml`. Title SHALL be `1.3. Infrastructure Requirements`.

description SHALL be:

Infrastructure requirements cover the installer method, platform/hypervisor
configuration, and network restrictions. This parent section groups checks
that validate the cluster was deployed on a supported infrastructure stack.

recommendation SHALL be:

This section is a section index. Use the installer-method, platform and hypervisor, and restricted-network children for scored recommendations. Do not patch Infrastructure in place from this parent.

verification SHALL be:

1. Print the Infrastructure object fields for this section (`status.platformStatus` includes API/ingress IPs and machineNetworks):
   `oc get infrastructure cluster -o custom-columns=PLATFORM:.status.platform,CP_TOPO:.status.controlPlaneTopology,INFRA_TOPO:.status.infrastructureTopology,TYPE:.status.platformStatus.type`
`cluster-config-v1` can contain trust bundles and BMC addresses — do not dump it here.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_3_infrastructure_requirements loads
- WHEN `get_entry` is called with `7.1.tsr.1_3_infrastructure_requirements`
- THEN the title is `1.3. Infrastructure Requirements`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_3_1_installer
`load_kb()` SHALL contain `7.1.tsr.1_3_1_installer` from `7_1_base_platform.toml`. Title SHALL be `1.3.1. Installer`.

description SHALL be:

The installation method (IPI, UPI, assisted) determines the supported
lifecycle operations and infrastructure management capabilities available.
Knowing the installer type is critical for troubleshooting and upgrades.

recommendation SHALL be:

Treat IPI versus UPI versus none as an architecture constraint, not a patch. Read the method from install-config keys only; do not dump the whole ConfigMap. Reconcile live platform and hypervisor on those children.

verification SHALL be:

1. Print install-config keys for the install method and platform. Extract only the relevant lines:
   `oc get configmap cluster-config-v1 -n kube-system -o jsonpath='{.data.install-config}' | grep -E '^(platform:|networking:|fips:)|baremetal:|vsphere:|aws:|^  none:'`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_3_1_installer loads
- WHEN `get_entry` is called with `7.1.tsr.1_3_1_installer`
- THEN the title is `1.3.1. Installer`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_3_2_platform_hypervisor
`load_kb()` SHALL contain `7.1.tsr.1_3_2_platform_hypervisor` from `7_1_base_platform.toml`. Title SHALL be `1.3.2. Platform/Hypervisor`.

description SHALL be:

Platform and hypervisor settings define how the cluster integrates with the
underlying infrastructure for machine management, storage provisioning, and
cloud provider operations.

recommendation SHALL be:

This section is a section index. Reconcile `status.platform` versus `status.platformStatus.type` and providerID on the platform and hypervisor children. BareMetal and public cloud: the hypervisor child does not apply.

verification SHALL be:

1. Compare `status.platform` to `status.platformStatus.type` on the Infrastructure object. `platformStatus` includes IPs:
   `oc get infrastructure cluster -o custom-columns=PLATFORM:.status.platform,TYPE:.status.platformStatus.type`
2. Confirm each node `spec.providerID` prefix matches the platform (`baremetalhost://`, `vsphere://`, `aws://`, `gcp://`, `azure://`, or empty on some UPI):
   `oc get nodes -o custom-columns=NAME:.metadata.name,PROVIDER:.spec.providerID`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_3_2_platform_hypervisor loads
- WHEN `get_entry` is called with `7.1.tsr.1_3_2_platform_hypervisor`
- THEN the title is `1.3.2. Platform/Hypervisor`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_3_2_1_platform
`load_kb()` SHALL contain `7.1.tsr.1_3_2_1_platform` from `7_1_base_platform.toml`. Title SHALL be `1.3.2.1. Platform`.

description SHALL be:

The platform type (AWS, vSphere, BareMetal, None, etc.) determines which
cloud-controller and machine-API integrations are active. Mismatches between
the declared platform and actual infrastructure cause provisioning failures.

recommendation SHALL be:

Make declared platform, platformStatus.type, and providerID prefix tell the same story. Fix the missing integration for that platform (Machine API, `BareMetalHost`, or cloud-provider-config). Do not add Machine API on None/UPI to make it look like IPI.

verification SHALL be:

1. Print declared platform and `platformStatus.type` on the Infrastructure object. They must match:
   `oc get infrastructure cluster -o custom-columns=PLATFORM:.status.platform,TYPE:.status.platformStatus.type`
2. Confirm each node `spec.providerID` prefix matches the platform (`baremetalhost://`, `vsphere://`, `aws://`, `gcp://`, `azure://`, or empty on some UPI):
   `oc get nodes -o custom-columns=NAME:.metadata.name,PROVIDER:.spec.providerID`
3. Verify the matching platform integration is present:
      - IPI: `oc get clusteroperator machine-api` and `oc get machine.machine.openshift.io -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase`
      - BareMetal: `oc get baremetalhost -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,STATE:.status.provisioning.state,ONLINE:.status.online` (BMC credentials live on the BMH object)
      - vSphere: `oc get configmap cloud-provider-config -n openshift-config` (can contain credentials)
      - `None` / UPI: missing Machine API is expected

impact SHALL be:

maintenance-window

impact_scope SHALL be:

Machine API, BareMetalHost, or cloud-provider integration

impact_detail SHALL be:

Fixing a mismatched platform usually means enabling the right integration and should be performed in a planned window. Do not add Machine API on None or UPI to make the cluster look like IPI.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_3_2_1_platform loads
- WHEN `get_entry` is called with `7.1.tsr.1_3_2_1_platform`
- THEN the title is `1.3.2.1. Platform`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_3_2_2_hypervisor_checks
`load_kb()` SHALL contain `7.1.tsr.1_3_2_2_hypervisor_checks` from `7_1_base_platform.toml`. Title SHALL be `1.3.2.2. Hypervisor Checks`.

description SHALL be:

For virtualized deployments, hypervisor compatibility and configuration
directly impacts cluster stability. CPU features, nested virtualization
settings, and resource overcommit affect node performance.

recommendation SHALL be:

Run hypervisor DMI checks only for vSphere, oVirt, OpenStack, or kubevirt; anything else is N/A. On those platforms, make providerID prefix and DMI vendor/product match. If DMI does not match, stop and confirm the host type before changing cluster objects.

verification SHALL be:

1. Check `status.platform`. This check applies only to vSphere, oVirt, OpenStack, or kubevirt:
   `oc get infrastructure cluster -o custom-columns=PLATFORM:.status.platform`
      BareMetal, AWS, Azure, GCP, and `None`: skip.
2. On virtual platforms, confirm `spec.providerID` prefix matches the hypervisor (`vsphere://`, `ovirt://`, `openstack://`, `kubevirt://`).
   `oc get nodes -o custom-columns=NAME:.metadata.name,PROVIDER:.spec.providerID,ARCH:.status.nodeInfo.architecture,OS:.status.nodeInfo.osImage,UUID:.status.nodeInfo.systemUUID`
3. Confirm DMI vendor and product match the hypervisor. `oc debug` starts a node pod — run only when step 1 confirms a virtual platform:
   `oc debug node/<name> -- chroot /host cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name`
      From a must-gather:
   `tar -xzf <must-gather>/nodes/<node>/sysinfo.tgz sys/class/dmi/id/product_name --to-stdout`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_3_2_2_hypervisor_checks loads
- WHEN `get_entry` is called with `7.1.tsr.1_3_2_2_hypervisor_checks`
- THEN the title is `1.3.2.2. Hypervisor Checks`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_3_3_restricted_network
`load_kb()` SHALL contain `7.1.tsr.1_3_3_restricted_network` from `7_1_base_platform.toml`. Title SHALL be `1.3.3. Restricted Network`.

description SHALL be:

Disconnected or restricted-network clusters require mirrored registries and
special proxy/trust configurations. Incomplete mirror setup causes image pull
failures and operator degradation.

recommendation SHALL be:

Give disconnected clusters a reachable mirror and a trust bundle that covers it. Fix ImageDigestMirrorSet / ImageTagMirrorSet (or leftover ICSP) and trustedCA if the registry is unreachable. Proxy allow-lists belong with the proxy check, not this row.

verification SHALL be:

1. Print the cluster-wide proxy endpoints:
   `oc get proxy cluster -o jsonpath='{.spec.httpProxy}{"\t"}{.spec.httpsProxy}{"\t"}{.spec.noProxy}{"\n"}'`
2. List image mirror maps. IDMS and ITMS are current; ICSP is deprecated:
   `oc get imagedigestmirrorset -o custom-columns=NAME:.metadata.name,SOURCE:.spec.imageDigestMirrors[*].source,MIRRORS:.spec.imageDigestMirrors[*].mirrors`
   `oc get imagetagmirrorset -o custom-columns=NAME:.metadata.name,SOURCE:.spec.imageTagMirrors[*].source,MIRRORS:.spec.imageTagMirrors[*].mirrors`
   `oc get imagecontentsourcepolicy -o custom-columns=NAME:.metadata.name,SOURCE:.spec.repositoryDigestMirrors[*].source,MIRRORS:.spec.repositoryDigestMirrors[*].mirrors`
3. Confirm the mirror registry is reachable and the cluster trustedCA bundle covers it. `cluster-config-v1` can contain trust bundles.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

image pull path (IDMS, ITMS, ICSP, and trustedCA)

impact_detail SHALL be:

Mirror and trust-bundle fixes affect new image pulls. They do not reboot nodes. Proxy allow-lists belong on the Proxy object, which rolls nodes through the Machine Config Operator.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installing-restricted-networks-preparations`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installing-restricted-networks-preparations`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installing-restricted-networks-preparations`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installing-restricted-networks-preparations`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installing-restricted-networks-preparations`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installing-restricted-networks-preparations`.

#### Scenario: 7.1.tsr.1_3_3_restricted_network loads
- WHEN `get_entry` is called with `7.1.tsr.1_3_3_restricted_network`
- THEN the title is `1.3.3. Restricted Network`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_minimum_hardware_requirements
`load_kb()` SHALL contain `7.1.tsr.1_4_minimum_hardware_requirements` from `7_1_base_platform.toml`. Title SHALL be `1.4. Minimum Hardware Requirements`.

description SHALL be:

OpenShift has documented minimum hardware requirements for control-plane and
worker nodes. Running below minimums causes instability, etcd performance
degradation, and scheduling failures.

recommendation SHALL be:

This section is a section index. Resize or replace undersized control-plane and worker nodes using the CPU, memory, and disk children. Do not lower requests to hide undersize.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_4_minimum_hardware_requirements loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_minimum_hardware_requirements`
- THEN the title is `1.4. Minimum Hardware Requirements`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_1_master_nodes
`load_kb()` SHALL contain `7.1.tsr.1_4_1_master_nodes` from `7_1_base_platform.toml`. Title SHALL be `1.4.1. Master Nodes`.

description SHALL be:

Control-plane (master) nodes run etcd, API server, controller-manager, and
scheduler. They require sufficient CPU, memory, and fast storage to maintain
cluster responsiveness under load.

recommendation SHALL be:

This section is a section index. Use the OS, CPU, memory, disk, schedulable, and kubelet children. A failing child is a node-size or OS issue, not a scheduler patch.

verification SHALL be:

1. List the control-plane (master) nodes:
   `oc get nodes -l node-role.kubernetes.io/master`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_4_1_master_nodes loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_1_master_nodes`
- THEN the title is `1.4.1. Master Nodes`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_1_1_operating_system_version
`load_kb()` SHALL contain `7.1.tsr.1_4_1_1_operating_system_version` from `7_1_base_platform.toml`. Title SHALL be `1.4.1.1. Operating System Version`.

description SHALL be:

Master nodes must run Red Hat Enterprise Linux CoreOS (RHCOS) at a version
compatible with the installed OCP release. Version mismatches indicate
incomplete upgrades or manual OS tampering.

recommendation SHALL be:

Run the same RHCOS image on every master for the installed OCP release. If any master differs, inspect `MachineConfigPool` and pending node updates. Do not mix RHEL on masters.

verification SHALL be:

1. Print the OS image on each master node:
   `oc get nodes -l node-role.kubernetes.io/master -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.osImage}{"\n"}{end}'`
2. Healthy is **PASS** when all masters report the same RHCOS version matching the cluster release.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

control-plane MachineConfigPool

impact_detail SHALL be:

Completing a stalled kubelet or machine-config rollout drains and reboots lagging nodes one at a time. On compact 3-node clusters where all nodes serve as both control-plane and worker, this affects 100% of cluster capacity.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#rhcos-about_architecture-rhcos`.

#### Scenario: 7.1.tsr.1_4_1_1_operating_system_version loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_1_1_operating_system_version`
- THEN the title is `1.4.1.1. Operating System Version`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_1_2_master_cpus
`load_kb()` SHALL contain `7.1.tsr.1_4_1_2_master_cpus` from `7_1_base_platform.toml`. Title SHALL be `1.4.1.2. Master CPUs`.

description SHALL be:

Control-plane nodes require a minimum of 4 vCPUs (8+ recommended for
production). Insufficient CPU causes API server latency, etcd leader
elections, and degraded cluster responsiveness.

recommendation SHALL be:

Resize or replace any control-plane node whose `status.capacity.cpu` is below 4 vCPU. The 8+ figure in the description is a production preference and does not change this threshold. Do not hide undersize with a kubelet tweak.

verification SHALL be:

1. Check CPU capacity (`status.capacity.cpu`) on each control-plane node. **PASS** is 4 or more vCPU:
   `oc get nodes -l node-role.kubernetes.io/master --no-headers -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu | awk '{print ($2+0>=4?"PASS":"FAIL"), $1, $2}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control-plane nodes

impact_detail SHALL be:

Resize or replace any undersized control-plane node. That work requires a maintenance window and can reduce API capacity while a master is remediated.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_4_1_2_master_cpus loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_1_2_master_cpus`
- THEN the title is `1.4.1.2. Master CPUs`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_1_3_master_memory
`load_kb()` SHALL contain `7.1.tsr.1_4_1_3_master_memory` from `7_1_base_platform.toml`. Title SHALL be `1.4.1.3. Master Memory`.

description SHALL be:

Control-plane nodes require minimum 16 GiB RAM (32+ recommended for
production). Insufficient memory causes OOM kills of critical components
like etcd and the API server. The TSR also warns when kubelet
`systemReserved.memory` is below its size-based expectation (for example
3 GiB reserved on a ~32 GiB node), even if capacity already meets 16 GiB.

recommendation SHALL be:

Resize or replace any control-plane node whose `status.capacity.memory` is below 16 GiB. When TSR flags `systemReserved.memory` below its size-based expectation, set `spec.kubeletConfig.systemReserved.memory` via `KubeletConfig` (`spec.autoSizingReserved: false` if overriding auto-size); do not treat that reserved WARNING as a 16 GiB FAIL.

verification SHALL be:

1. Check memory capacity (`status.capacity.memory`, in Ki) on each control-plane node. **PASS** is 16 GiB (16777216 Ki) or more:
   `oc get nodes -l node-role.kubernetes.io/master --no-headers -o custom-columns=NAME:.metadata.name,MEM:.status.capacity.memory | awk '{print ($2+0>=16777216?"PASS":"FAIL"), $1, $2}'`
2. Print kubelet `systemReserved.memory` from each control-plane node's `configz`. This step confirms reservation and does not FAIL on the 16 GiB capacity bar. **INFO** if `systemReserved.memory` is missing.
   `oc get nodes -l node-role.kubernetes.io/master --no-headers -o custom-columns=NAME:.metadata.name | while read -r node; do reserved=$(oc get --raw /api/v1/nodes/${node}/proxy/configz | jq -r '.kubeletconfig.systemReserved.memory // empty'); if [ -z "$reserved" ]; then echo "INFO NODE=${node} systemReserved.memory missing"; else echo "INFO NODE=${node} systemReserved.memory=${reserved}"; fi; done`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control-plane nodes

impact_detail SHALL be:

Resize or replace any control-plane node below 16 GiB. A KubeletConfig systemReserved change drains and reboots the targeted pool instead.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_4_1_3_master_memory loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_1_3_master_memory`
- THEN the title is `1.4.1.3. Master Memory`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_1_4_master_disk
`load_kb()` SHALL contain `7.1.tsr.1_4_1_4_master_disk` from `7_1_base_platform.toml`. Title SHALL be `1.4.1.4. Master Disk`.

description SHALL be:

Control-plane nodes require fast storage (SSD/NVMe recommended) with
sufficient IOPS for etcd. Slow or full disks cause etcd latency warnings,
compaction failures, and potential data loss.

recommendation SHALL be:

Plan larger control-plane disks or a node replacement when `ephemeral-storage` is below 100 GiB. Prefer collect `11_hardware` sysinfo when present. Do not confuse this with DiskPressure eviction.

verification SHALL be:

1. Check ephemeral-storage capacity (`status.capacity.ephemeral-storage`, in Ki) on each control-plane node. **PASS** is 100 GiB (104857600 Ki) or more. This is the API fallback, not physical disk:
   `oc get nodes -l node-role.kubernetes.io/master --no-headers -o custom-columns=NAME:.metadata.name,EPHEMERAL:.status.capacity.ephemeral-storage | awk '{print ($2+0>=104857600?"PASS":"FAIL"), $1, $2}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control-plane disks or node replacement

impact_detail SHALL be:

Growing ephemeral-storage below 100 GiB means larger disks or replacing the master and should be performed in a planned window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_4_1_4_master_disk loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_1_4_master_disk`
- THEN the title is `1.4.1.4. Master Disk`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_1_5_master_schedulable
`load_kb()` SHALL contain `7.1.tsr.1_4_1_5_master_schedulable` from `7_1_base_platform.toml`. Title SHALL be `1.4.1.5. Master Schedulable`.

description SHALL be:

Control-plane schedulability is topology-specific. Compact 3-node and SNO
clusters must keep masters schedulable. Dedicated-worker clusters often set
`mastersSchedulable` to false so user pods stay off the control plane.

recommendation SHALL be:

Set `mastersSchedulable` to match topology. Leave it true on compact and single-node clusters so the control plane can run workloads. Patch it to false on dedicated-worker clusters unless user pods on masters are an accepted design. Changing the flag does not resize nodes.

verification SHALL be:

1. Print `spec.mastersSchedulable` from the Scheduler object:
   `oc get scheduler cluster -o jsonpath='{.spec.mastersSchedulable}{"\n"}'`
2. Print the unique node roles to determine topology:
   `oc get nodes --no-headers | awk '{print $3}' | sort -u`
      Compact or SNO shows one line with `control-plane,master,worker`. Dedicated-worker topology shows separate `control-plane,master` and `worker` lines.
3. On compact or SNO clusters, `mastersSchedulable` should be true.
4. On a dedicated-worker cluster, set it to false if the control plane should not run user pods:
   `oc patch scheduler cluster --type=merge -p '{"spec":{"mastersSchedulable":false}}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

control-plane scheduling

impact_detail SHALL be:

Changing mastersSchedulable to false prevents new workloads from landing on control-plane nodes but does not evict existing pods or reboot nodes. On compact 3-node clusters where all nodes serve as both control-plane and worker, this affects 100% of cluster capacity.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-scheduler-about_nodes-scheduler-default`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-scheduler-about_nodes-scheduler-default`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-scheduler-about_nodes-scheduler-default`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-scheduler-about_nodes-scheduler-default`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-scheduler-about_nodes-scheduler-default`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-scheduler-about_nodes-scheduler-default`.

#### Scenario: 7.1.tsr.1_4_1_5_master_schedulable loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_1_5_master_schedulable`
- THEN the title is `1.4.1.5. Master Schedulable`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_1_6_master_kubernetes_version
`load_kb()` SHALL contain `7.1.tsr.1_4_1_6_master_kubernetes_version` from `7_1_base_platform.toml`. Title SHALL be `1.4.1.6. Master Kubernetes Version`.

description SHALL be:

All control-plane nodes should report the same kubelet version matching the
cluster's Kubernetes release. Version skew indicates incomplete upgrades or
node join failures.

recommendation SHALL be:

Bring every master kubeletVersion to the cluster Kubernetes release. If they differ, inspect MCO and pending node updates. Do not start another upgrade on mixed kubelets.

verification SHALL be:

1. Print the kubelet version on each master node:
   `oc get nodes -l node-role.kubernetes.io/master -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'`
2. Healthy is **PASS** when all masters report the same kubelet version.
3. If versions differ, check Machine Config Operator status and pending node updates.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

control-plane MachineConfigPool

impact_detail SHALL be:

Completing a stalled kubelet or machine-config rollout drains and reboots lagging nodes one at a time. On compact 3-node clusters where all nodes serve as both control-plane and worker, this affects 100% of cluster capacity.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#architecture-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#architecture-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#architecture-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#architecture-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#architecture-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#architecture-overview`.

#### Scenario: 7.1.tsr.1_4_1_6_master_kubernetes_version loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_1_6_master_kubernetes_version`
- THEN the title is `1.4.1.6. Master Kubernetes Version`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_2_non_master_nodes
`load_kb()` SHALL contain `7.1.tsr.1_4_2_non_master_nodes` from `7_1_base_platform.toml`. Title SHALL be `1.4.2. Non-Master Nodes`.

description SHALL be:

Worker and infrastructure nodes run application workloads and platform
services. They must meet minimum resource requirements for the workloads
scheduled to them.

recommendation SHALL be:

This section is a section index. Use the OS, CPU, memory, disk, and architecture children. On compact clusters the worker set is the same nodes as the control plane.

verification SHALL be:

1. List the worker-role nodes. On compact clusters this is the same set as masters:
   `oc get nodes -l node-role.kubernetes.io/worker`
      Confirm topology with unique roles:
   `oc get nodes --no-headers | awk '{print $3}' | sort -u`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_4_2_non_master_nodes loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_2_non_master_nodes`
- THEN the title is `1.4.2. Non-Master Nodes`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_2_1_operating_system_version
`load_kb()` SHALL contain `7.1.tsr.1_4_2_1_operating_system_version` from `7_1_base_platform.toml`. Title SHALL be `1.4.2.1. Operating System Version`.

description SHALL be:

Worker nodes may run RHCOS or RHEL 8.6+. Mixed images are supported when
workloads have matching images.

recommendation SHALL be:

Run RHCOS or RHEL 8.6+ on workers. Replace or reinstall any node whose image is neither. Control-plane RHCOS is a separate OS check.

verification SHALL be:

1. Print the unique OS images (`status.nodeInfo.osImage`) across worker nodes:
   `oc get nodes -l node-role.kubernetes.io/worker --no-headers -o custom-columns=OS:.status.nodeInfo.osImage | sort -u`
2. **PASS** when all workers run RHCOS or RHEL 8.6+.
3.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

worker MachineConfigPool or node reinstall

impact_detail SHALL be:

Replace or reinstall workers that are not RHCOS or RHEL 8.6+. Completing the MachineConfigPool drains and reboots those nodes one at a time.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#rhcos-about_architecture-rhcos`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#rhcos-about_architecture-rhcos`.

#### Scenario: 7.1.tsr.1_4_2_1_operating_system_version loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_2_1_operating_system_version`
- THEN the title is `1.4.2.1. Operating System Version`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_2_2_node_cpus
`load_kb()` SHALL contain `7.1.tsr.1_4_2_2_node_cpus` from `7_1_base_platform.toml`. Title SHALL be `1.4.2.2. Node CPUs`.

description SHALL be:

Worker nodes require a minimum of 2 vCPUs. Insufficient CPU causes scheduling
failures and noisy-neighbor latency for application pods.

recommendation SHALL be:

Add CPU or replace any worker whose `status.capacity.cpu` is below 2 vCPU. Compact clusters use the same nodes as the control plane, which scores at 4 vCPU. Do not lower requests to hide undersize.

verification SHALL be:

1. Check CPU capacity (`status.capacity.cpu`) on each worker node. **PASS** is 2 or more vCPU:
   `oc get nodes -l node-role.kubernetes.io/worker --no-headers -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu | awk '{print ($2+0>=2?"PASS":"FAIL"), $1, $2}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

worker nodes

impact_detail SHALL be:

Resize or replace any undersized worker. That work requires a maintenance window and drains the node while it is remediated.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_4_2_2_node_cpus loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_2_2_node_cpus`
- THEN the title is `1.4.2.2. Node CPUs`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_2_3_node_memory
`load_kb()` SHALL contain `7.1.tsr.1_4_2_3_node_memory` from `7_1_base_platform.toml`. Title SHALL be `1.4.2.3. Node Memory`.

description SHALL be:

Worker nodes require a minimum of 8 GiB RAM. Insufficient memory causes OOM
kills of application pods and kubelet eviction.

recommendation SHALL be:

Add memory or replace any worker whose `status.capacity.memory` is below 8 GiB. Compact clusters use the same nodes as the control plane, which scores at 16 GiB.

verification SHALL be:

1. Check memory capacity (`status.capacity.memory`, in Ki) on each worker node. **PASS** is 8 GiB (8388608 Ki) or more:
   `oc get nodes -l node-role.kubernetes.io/worker --no-headers -o custom-columns=NAME:.metadata.name,MEM:.status.capacity.memory | awk '{print ($2+0>=8388608?"PASS":"FAIL"), $1, $2}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

worker nodes

impact_detail SHALL be:

Resize or replace any undersized worker. That work requires a maintenance window and drains the node while it is remediated.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_4_2_3_node_memory loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_2_3_node_memory`
- THEN the title is `1.4.2.3. Node Memory`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_2_4_node_disk
`load_kb()` SHALL contain `7.1.tsr.1_4_2_4_node_disk` from `7_1_base_platform.toml`. Title SHALL be `1.4.2.4. Node Disk`.

description SHALL be:

Worker nodes require sufficient disk space for container images, ephemeral
storage, and logs. Disk pressure causes pod evictions and scheduling failures
that impact application availability.

recommendation SHALL be:

Plan larger worker disks when `ephemeral-storage` is below 100 GiB. Prefer collect `11_hardware` lsblk when present. A thin worker disk is not a control-plane etcd emergency.

verification SHALL be:

1. Check ephemeral-storage capacity (`status.capacity.ephemeral-storage`, in Ki) on each worker node. **PASS** is 100 GiB (104857600 Ki) or more. This is the API fallback, not physical disk:
   `oc get nodes -l node-role.kubernetes.io/worker --no-headers -o custom-columns=NAME:.metadata.name,EPHEMERAL:.status.capacity.ephemeral-storage | awk '{print ($2+0>=104857600?"PASS":"FAIL"), $1, $2}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

worker disks or node replacement

impact_detail SHALL be:

Plan larger worker disks when ephemeral-storage is below 100 GiB. That work requires a maintenance window and may involve node drain or replacement.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_4_2_4_node_disk loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_2_4_node_disk`
- THEN the title is `1.4.2.4. Node Disk`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_4_2_5_node_architecture
`load_kb()` SHALL contain `7.1.tsr.1_4_2_5_node_architecture` from `7_1_base_platform.toml`. Title SHALL be `1.4.2.5. Node Architecture`.

description SHALL be:

Node CPU architecture (amd64, arm64, ppc64le, s390x) must be consistent
or properly handled with multi-arch scheduling. Mismatched architectures
without proper image support cause pod `CrashLoopBackOff`.

recommendation SHALL be:

Keep one architecture, or constrain scheduling and standardize nodes if mixed but workloads are single-arch. Mixed architecture is acceptable when images and scheduling cover each arch. Do not treat mixed arch as a failed node.

verification SHALL be:

1. Print the unique CPU architectures (`status.nodeInfo.architecture`) across all nodes. A single value is the typical case; mixed architectures require matching images and scheduling constraints:
   `oc get nodes --no-headers -o custom-columns=ARCH:.status.nodeInfo.architecture | sort -u`

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads that cannot run on every architecture

impact_detail SHALL be:

Constraining scheduling or standardizing images reschedules affected pods. Replacing nodes to a single architecture is a maintenance window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#architecture-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#architecture-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#architecture-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#architecture-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#architecture-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#architecture-overview`.

#### Scenario: 7.1.tsr.1_4_2_5_node_architecture loads
- WHEN `get_entry` is called with `7.1.tsr.1_4_2_5_node_architecture`
- THEN the title is `1.4.2.5. Node Architecture`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_other_basic_checks
`load_kb()` SHALL contain `7.1.tsr.1_5_other_basic_checks` from `7_1_base_platform.toml`. Title SHALL be `1.5. Other Basic Checks`.

description SHALL be:

This parent section groups additional platform-level checks covering SELinux,
DNS, networking, time synchronization, FIPS, and security configurations that
are foundational to cluster health.

recommendation SHALL be:

This section is a section index. Use the child that matches the finding: SELinux, DNS, NetworkManager, CIDRs, firewall, proxy, time, SDN, swap, and the remaining host and identity rows. This parent does not score those items.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-overview_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_5_other_basic_checks loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_other_basic_checks`
- THEN the title is `1.5. Other Basic Checks`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_1_selinux
`load_kb()` SHALL contain `7.1.tsr.1_5_1_selinux` from `7_1_base_platform.toml`. Title SHALL be `1.5.1. SELinux`.

description SHALL be:

SELinux must be in Enforcing mode on all OCP nodes. Permissive or Disabled
modes leave the cluster vulnerable and are unsupported. Red Hat support
requires Enforcing mode for all production deployments.

recommendation SHALL be:

Set SELinux to Enforcing on every node. Find the MachineConfig or host change that set Permissive or Disabled and revert. Do not leave Permissive as accepted risk on RHCOS.

verification SHALL be:

1. Check the SELinux mode on each node:
   `oc debug node/<name> -- chroot /host getenforce`
2. **PASS** when all nodes report `Enforcing`.
3. If a node shows `Permissive` or Disabled, check MachineConfig or host-level changes that altered SELinux.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes whose MachineConfig set Permissive or Disabled

impact_detail SHALL be:

Applying a desired MachineConfig drains and reboots nodes in that pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`.

#### Scenario: 7.1.tsr.1_5_1_selinux loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_1_selinux`
- THEN the title is `1.5.1. SELinux`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_2_dns
`load_kb()` SHALL contain `7.1.tsr.1_5_2_dns` from `7_1_base_platform.toml`. Title SHALL be `1.5.2. DNS`.

description SHALL be:

DNS is a foundational cluster service. The DNS operator, CoreDNS pods, and
upstream resolver configuration must all be healthy for service discovery,
pod networking, and operator functionality.

recommendation SHALL be:

Bring the DNS Operator to `Available=True`, `Progressing=False`, `Degraded=False`. If it is degraded, inspect dns.operator default conditions, then forwarding, CoreDNS pods, and DNS alerts. Do not restart CoreDNS until the operator condition is understood.

verification SHALL be:

1. Check the DNS Operator object `dns.operator default` (`Available=True`, `Progressing=False`, `Degraded=False`):
   `oc get dns.operator default -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}' | awk -F= '$1=="Available"{a=$2} $1=="Progressing"{p=$2} $1=="Degraded"{d=$2} END{print (a=="True" && p=="False" && d=="False"?"PASS":"FAIL"), "Available="a, "Progressing="p, "Degraded="d}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

DNS Operator and CoreDNS pods

impact_detail SHALL be:

Restoring dns.operator default rolls CoreDNS and can briefly break name resolution. It does not reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#nw-dns-operator_dns-operator`.

#### Scenario: 7.1.tsr.1_5_2_dns loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_2_dns`
- THEN the title is `1.5.2. DNS`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_2_1_dns_config
`load_kb()` SHALL contain `7.1.tsr.1_5_2_1_dns_config` from `7_1_base_platform.toml`. Title SHALL be `1.5.2.1. DNS Config`.

description SHALL be:

The cluster DNS configuration defines upstream resolvers and forwarding rules.
Misconfigured DNS settings cause resolution failures for external services
and can cascade into operator degradation.

recommendation SHALL be:

Fix the upstream type that is actually in use on `dns.operator default`. `dns cluster` is baseDomain. Leave `spec.servers` empty unless you need split-horizon. `SystemResolvConf` means node resolv.conf; `Network` means an explicit IP.

verification SHALL be:

1. Print the DNS Operator config (`dns.operator default`). The separate `dns cluster` (config.openshift.io) holds `baseDomain`, not these fields:
   `oc get dns.operator default -o custom-columns=NAME:.metadata.name,UPSTREAM:.spec.upstreamResolvers.upstreams[*].type,SERVERS:.spec.servers`
2. `spec.servers` is usually `<none>` (the default). It is only set for split-horizon or extra forwarding zones.
3. `UPSTREAM` is `.spec.upstreamResolvers.upstreams[*].type`:
      - `SystemResolvConf`: CoreDNS forwards to each node's `/etc/resolv.conf`.
      - `Network`: an explicit address and port are specified in this CR.
4. If type is `Network`, the upstream is that IP. If `SystemResolvConf`, the upstream is the node resolver.

impact SHALL be:

workload-shift

impact_scope SHALL be:

CoreDNS forwarding and listen configuration

impact_detail SHALL be:

Patching dns.operator default rolls CoreDNS pods and can briefly break name resolution. It does not reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#nw-dns-operator_dns-operator`.

#### Scenario: 7.1.tsr.1_5_2_1_dns_config loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_2_1_dns_config`
- THEN the title is `1.5.2.1. DNS Config`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_2_2_dns_pods
`load_kb()` SHALL contain `7.1.tsr.1_5_2_2_dns_pods` from `7_1_base_platform.toml`. Title SHALL be `1.5.2.2. DNS Pods`.

description SHALL be:

CoreDNS pods in the openshift-dns namespace handle all cluster DNS queries.
Pods not in Running state or with high restart counts indicate DNS service
degradation affecting the entire cluster.

recommendation SHALL be:

Bring CoreDNS pods to Running on each node. Inspect logs and describe only for `CrashLoopBackOff` or not-Running instances. Restarts over a long uptime are not by themselves a failure.

verification SHALL be:

1. List the CoreDNS pods in openshift-dns:
   `oc get pods -n openshift-dns -o wide`
2. **PASS** when all pods are `Running`. `CrashLoopBackOff` is a **FAIL**. Restarts over a long uptime are not by themselves a failure.
3. For an unhealthy pod, check its logs:
   `oc logs -n openshift-dns <pod-name>`
4. Describe the pod for events and status:
   `oc describe pod -n openshift-dns <pod-name>`

impact SHALL be:

workload-shift

impact_scope SHALL be:

CoreDNS DaemonSet

impact_detail SHALL be:

Bringing CrashLoop CoreDNS back to Running restarts DNS pods on those nodes and can briefly break name resolution.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#nw-dns-operator_dns-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#nw-dns-operator_dns-operator`.

#### Scenario: 7.1.tsr.1_5_2_2_dns_pods loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_2_2_dns_pods`
- THEN the title is `1.5.2.2. DNS Pods`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_3_network_manager
`load_kb()` SHALL contain `7.1.tsr.1_5_3_network_manager` from `7_1_base_platform.toml`. Title SHALL be `1.5.3. Network Manager`.

description SHALL be:

NetworkManager is required on all RHCOS nodes for network configuration
management. It must be active and managing the primary interfaces for
OVN-Kubernetes or OpenShift SDN to function correctly.

recommendation SHALL be:

Keep NetworkManager active and the primary NIC connected on RHCOS. If NM is down or the NIC is unmanaged, fix via MachineConfig so it persists. Do not disable NM to simplify networking.

verification SHALL be:

1. Check that NetworkManager is active on each node:
   `oc debug node/<name> -- chroot /host systemctl status NetworkManager`
2. Confirm the primary interfaces are managed:
   `oc debug node/<name> -- chroot /host nmcli device status`
**PASS** when the primary NIC shows `active` / `connected`. If NM is down or the NIC is unmanaged, fix via MachineConfig so it persists.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

RHCOS nodes via MachineConfig

impact_detail SHALL be:

Applying a desired MachineConfig drains and reboots nodes in that pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#networking-operators-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#networking-operators-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#networking-operators-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#networking-operators-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#networking-operators-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#networking-operators-overview`.

#### Scenario: 7.1.tsr.1_5_3_network_manager loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_3_network_manager`
- THEN the title is `1.5.3. Network Manager`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_4_shared_network
`load_kb()` SHALL contain `7.1.tsr.1_5_4_shared_network` from `7_1_base_platform.toml`. Title SHALL be `1.5.4. Shared Network`.

description SHALL be:

In shared network environments multiple clusters or services share the same
L2/L3 network segment. This requires careful IP allocation, VLAN management,
and awareness of broadcast domain impacts.

recommendation SHALL be:

Keep clusterNetwork and serviceNetwork from overlapping each other or machineNetwork. Overlap is an install-time CIDR problem — plan a rebuild or documented network migration. Node InternalIP versus machineNetwork is a separate addressing check.

verification SHALL be:

1. Print the pod and service CIDRs from the Network config object. `clusterNetwork` items have `cidr` and `hostPrefix`; `serviceNetwork` is a list of CIDR strings:
   `oc get network.config cluster -o custom-columns=CLUSTER:.spec.clusterNetwork[*].cidr,HOSTPREFIX:.spec.clusterNetwork[*].hostPrefix,SERVICE:.spec.serviceNetwork[*]`
2. **PASS** when those CIDRs do not overlap each other.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster-wide CIDRs

impact_detail SHALL be:

Overlapping cluster, service, or machine networks is an install-time CIDR problem. The fix is a rebuild or a documented network migration.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#networking-operators-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#networking-operators-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#networking-operators-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#networking-operators-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#networking-operators-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#networking-operators-overview`.

#### Scenario: 7.1.tsr.1_5_4_shared_network loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_4_shared_network`
- THEN the title is `1.5.4. Shared Network`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_5_firewalls
`load_kb()` SHALL contain `7.1.tsr.1_5_5_firewalls` from `7_1_base_platform.toml`. Title SHALL be `1.5.5. Firewalls`.

description SHALL be:

OpenShift requires specific ports open between nodes, to external registries,
and to cloud APIs. Missing firewall rules cause intermittent failures in
node communication, image pulls, and operator reconciliation.

recommendation SHALL be:

Allow Geneve 6081 (OVN) plus API, etcd, and kubelet between the right nodes. `network.config` names the CNI only; it does not list ports. If overlay or API ports are blocked, change security groups, ACLs, or host firewall. Do not patch Network.config to open ports.

verification SHALL be:

1. Print the CNI plugin name from the Network config:
   `oc get network.config cluster -o jsonpath='{.spec.networkType}{"\n"}'`
2. Confirm these ports are allowed in security groups, ACLs, or host firewall:
      - API 6443/tcp to control-plane
      - etcd 2379/tcp and 2380/tcp between control-plane nodes
      - kubelet 10250/tcp to all nodes
      - OVNKubernetes: Geneve 6081/udp between all nodes
      - OpenShiftSDN (removed in 4.17): VXLAN 4789/udp — ignore on current releases
3. Curl of `/healthz` is not a firewall matrix.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

security groups, ACLs, or host firewall

impact_detail SHALL be:

Opening Geneve 6081, API, etcd, and kubelet can drop overlay or API traffic until the new rules are correct. Do not patch Network.config to open ports.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_5_5_firewalls loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_5_firewalls`
- THEN the title is `1.5.5. Firewalls`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_6_proxy
`load_kb()` SHALL contain `7.1.tsr.1_5_6_proxy` from `7_1_base_platform.toml`. Title SHALL be `1.5.6. Proxy`.

description SHALL be:

Cluster-wide proxy configuration controls how nodes and pods reach external
networks. Misconfigured proxy settings cause image pull failures, operator
degradation, and inability to reach update services.

recommendation SHALL be:

If a proxy is set, include cluster, service, and machine CIDRs plus `.cluster.local` in noProxy, and name trustedCA if TLS intercept is in play. If operators cannot pull or update, fix noProxy and trustedCA before changing channels. Leave a working proxy in place if the site requires it. Empty proxy is also valid.

verification SHALL be:

1. Print `httpProxy`, `httpsProxy`, and `noProxy` from the Proxy object:
   `oc get proxy cluster -o jsonpath='{.spec.httpProxy}{"\t"}{.spec.httpsProxy}{"\t"}{.spec.noProxy}{"\n"}'`
2. If a proxy is set, `noProxy` must include clusterNetwork, serviceNetwork, machineNetwork, and `.cluster.local`. Empty proxy is also valid.
3. Print the trustedCA ConfigMap name:
   `oc get proxy cluster -o jsonpath='{.spec.trustedCA.name}{"\n"}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

cluster-wide egress

impact_detail SHALL be:

Proxy configuration changes roll out through Machine Config Operator and may cause node reboots if trustedCA bundle changes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#enable-cluster-wide-proxy_config-cluster-wide-proxy`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#enable-cluster-wide-proxy_config-cluster-wide-proxy`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#enable-cluster-wide-proxy_config-cluster-wide-proxy`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#enable-cluster-wide-proxy_config-cluster-wide-proxy`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#enable-cluster-wide-proxy_config-cluster-wide-proxy`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#enable-cluster-wide-proxy_config-cluster-wide-proxy`.

#### Scenario: 7.1.tsr.1_5_6_proxy loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_6_proxy`
- THEN the title is `1.5.6. Proxy`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_7_time
`load_kb()` SHALL contain `7.1.tsr.1_5_7_time` from `7_1_base_platform.toml`. Title SHALL be `1.5.7. Time`.

description SHALL be:

Accurate time synchronization across all nodes is critical for certificate
validation, etcd consistency, log correlation, and distributed system
coordination. Clock skew causes cryptographic failures and split-brain.

recommendation SHALL be:

This section is a section index. Fix NTP, chrony offset, PTP, or firing clock alerts on the child that matches. Do not suppress clock alerts from this parent.

verification SHALL be:

1. This is a section index. Check the child rows for NTP, chrony, PTP, and clock alert specifics.
2. Print chrony tracking on a node:
   `oc debug node/<name> -- chroot /host chronyc tracking`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_5_7_time loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_7_time`
- THEN the title is `1.5.7. Time`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_7_1_ntp
`load_kb()` SHALL contain `7.1.tsr.1_5_7_1_ntp` from `7_1_base_platform.toml`. Title SHALL be `1.5.7.1. NTP`.

description SHALL be:

NTP time synchronization ensures all cluster nodes maintain accurate clocks.
RHCOS uses chrony by default, but legacy NTP configuration may exist on
RHEL worker nodes.

recommendation SHALL be:

Synchronize NTP on every node. RHCOS uses chrony; RHEL workers need chronyd active. If NTP is not synchronized, fix the source and chronyd.

verification SHALL be:

1. Print the time synchronization status on each node:
   `oc debug node/<name> -- chroot /host timedatectl status`
2. **PASS** when NTP is synchronized and the time source is reachable.
3. On RHEL workers, confirm `chronyd` is active:
   `oc debug node/<name> -- chroot /host systemctl status chronyd`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes whose time source is set via MachineConfig

impact_detail SHALL be:

Applying a desired MachineConfig drains and reboots nodes in that pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_5_7_1_ntp loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_7_1_ntp`
- THEN the title is `1.5.7.1. NTP`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_7_2_chrony
`load_kb()` SHALL contain `7.1.tsr.1_5_7_2_chrony` from `7_1_base_platform.toml`. Title SHALL be `1.5.7.2. Chrony`.

description SHALL be:

Chrony is the default NTP implementation on RHCOS. It must be configured with
reachable time sources. This check's verification bar is clock offset under 100 ms.

recommendation SHALL be:

Keep a reachable chrony source and offset under 100ms. If offset is high or sources are unreachable, fix chrony config via MachineConfig. PTP is only in scope when the design uses it. Firing clock alerts mean the node is already skewing.

verification SHALL be:

1. Print chrony tracking on each node:
   `oc debug node/<name> -- chroot /host chronyc tracking`
2. List the chrony sources:
   `oc debug node/<name> -- chroot /host chronyc sources -v`
3. **PASS** when the reported offset is under 100 ms (`< 100ms`) and **at least three** time sources are configured and reachable. Two sources that agree can still yield a usable time; two sources that disagree is **FAIL** because chrony cannot tell which one is correct without information from outside the protocol. One source is **FAIL** for the same reason.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the chrony MachineConfig pool

impact_detail SHALL be:

Applying a desired MachineConfig drains and reboots nodes in that pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `kcs` -> `https://access.redhat.com/solutions/778603`.

#### Scenario: 7.1.tsr.1_5_7_2_chrony loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_7_2_chrony`
- THEN the title is `1.5.7.2. Chrony`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_7_3_ptp
`load_kb()` SHALL contain `7.1.tsr.1_5_7_3_ptp` from `7_1_base_platform.toml`. Title SHALL be `1.5.7.3. PTP`.

description SHALL be:

Precision Time Protocol provides sub-microsecond time accuracy for workloads
requiring strict synchronization (telco, financial). PTP operator and
grandmaster clock configuration must be validated where deployed.

recommendation SHALL be:

Leave PTP absent unless it is in the design. If the PTP operator is installed, keep a PtpConfig and running openshift-ptp pods. Empty subscription grep is N/A; if the operator is installed but pods are not Running, inspect that namespace.

verification SHALL be:

1. Check whether the PTP Operator subscription exists. Empty output means PTP is not installed, skip:
   `oc get subscription -A | grep ptp`
2. If present, list the PtpConfig profiles:
   `oc get ptpconfig -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PROFILES:.spec.profile[*].name`
3. Confirm the PTP pods are Running:
   `oc get pods -n openshift-ptp`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

openshift-ptp operator and PtpConfig

impact_detail SHALL be:

Repairing PtpConfig rolls PTP pods. It does not reboot cluster nodes. Unused PTP is not a failure.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#about-ptp_using-ptp`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#about-ptp_using-ptp`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#about-ptp_using-ptp`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#about-ptp_using-ptp`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#about-ptp_using-ptp`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#about-ptp_using-ptp`.

#### Scenario: 7.1.tsr.1_5_7_3_ptp loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_7_3_ptp`
- THEN the title is `1.5.7.3. PTP`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_7_4_clock_alerts
`load_kb()` SHALL contain `7.1.tsr.1_5_7_4_clock_alerts` from `7_1_base_platform.toml`. Title SHALL be `1.5.7.4. Clock Alerts`.

description SHALL be:

Clock-related alerts (ClockSkewDetected, NTPDaemonUnreachable) indicate
time synchronization failures that can cascade into certificate validation
errors and etcd consistency issues.

recommendation SHALL be:

Clear NodeClockSkewDetected and NodeClockNotSynchronising. If an alert is firing, fix time sync on that node (NTP and chrony) before you touch etcd. Do not suppress the alert as accepted risk while etcd and certs depend on the clock.

verification SHALL be:

1. List the clock alerting rules from the PrometheusRule in openshift-monitoring. The shipped rules are `NodeClockSkewDetected` and `NodeClockNotSynchronising`:
   `oc get prometheusrule node-exporter-rules -n openshift-monitoring -o jsonpath='{range .spec.groups[*].rules[?(@.alert)]}{.alert}{"\n"}{end}'`
2. Check which of those are currently firing. Empty output means **PASS**:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname | test("NodeClock|ClockSkew|NTPDaemon")) | {state, alertname: .labels.alertname, severity: .labels.severity}'`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes named by NodeClockSkew or NodeClockNotSynchronising

impact_detail SHALL be:

Applying a desired MachineConfig drains and reboots nodes in that pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-special-config-chrony_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_5_7_4_clock_alerts loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_7_4_clock_alerts`
- THEN the title is `1.5.7.4. Clock Alerts`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_8_sdn
`load_kb()` SHALL contain `7.1.tsr.1_5_8_sdn` from `7_1_base_platform.toml`. Title SHALL be `1.5.8. SDN`.

description SHALL be:

The cluster network plugin (OVN-Kubernetes) provides pod networking, service
load balancing, and network policy enforcement. OVN-Kubernetes is the only
supported network plugin from OCP 4.17 onward. Network health is critical for
all pod-to-pod and pod-to-service communication.

recommendation SHALL be:

Bring the network ClusterOperator to `Available=True`, `Progressing=False`, `Degraded=False` and keep OVN-Kubernetes pods Running. If the operator is degraded, read network CO conditions, then inspect OVN pods. Do not change networkType in place. OpenShiftSDN is gone as of 4.17.

verification SHALL be:

1. Check the network ClusterOperator (`Available=True`, `Progressing=False`, `Degraded=False`):
   `oc get co network --no-headers | awk '{print ($3=="True" && $4=="False" && $5=="False"?"PASS":"FAIL"), $0}'`
2. If the operator is not healthy, print its conditions:
   `oc get clusteroperator network -o jsonpath='{range .status.conditions[*]}{.type}={.status} reason={.reason}{"\n"}{end}'`
3. Print the network plugin type:
   `oc get network.config cluster -o jsonpath='{.spec.networkType}'`
4. Confirm the OVN-Kubernetes pods are Running:
   `oc get pods -n openshift-ovn-kubernetes`

impact SHALL be:

workload-shift

impact_scope SHALL be:

OVN-Kubernetes pods and cluster networking

impact_detail SHALL be:

Restoring the network ClusterOperator rolls OVN pods and can interrupt east-west traffic. Do not change networkType in place.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#about-ovn-kubernetes`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#about-ovn-kubernetes`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#about-ovn-kubernetes`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#about-ovn-kubernetes`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#about-ovn-kubernetes`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#about-ovn-kubernetes`.

#### Scenario: 7.1.tsr.1_5_8_sdn loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_8_sdn`
- THEN the title is `1.5.8. SDN`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_9_swap
`load_kb()` SHALL contain `7.1.tsr.1_5_9_swap` from `7_1_base_platform.toml`. Title SHALL be `1.5.9. Swap`.

description SHALL be:

Kubernetes does not support swap on nodes by default. Enabled swap can cause
unpredictable pod memory behavior, OOM kill ordering issues, and is
unsupported in production OCP deployments.

recommendation SHALL be:

Disable swap on every node. If swap is enabled, disable it via MachineConfig so it survives reboot. Do not leave swap as accepted risk. Empty `swapon --show` means swap is already off.

verification SHALL be:

1. Check whether swap is enabled on each node:
   `oc debug node/<name> -- chroot /host swapon --show`
2. **PASS** when the output is empty (no swap configured).
3. If swap appears, it should be disabled via MachineConfig so the change persists across reboots.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes with swap enabled

impact_detail SHALL be:

Applying a desired MachineConfig drains and reboots nodes in that pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-swap-memory_nodes-nodes-resources-configuring`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-nodes-swap-memory_nodes-nodes-resources-configuring`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-nodes-swap-memory_nodes-nodes-resources-configuring`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-nodes-swap-memory_nodes-nodes-resources-configuring`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-nodes-swap-memory_nodes-nodes-resources-configuring`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-nodes-swap-memory_nodes-nodes-resources-configuring`.

#### Scenario: 7.1.tsr.1_5_9_swap loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_9_swap`
- THEN the title is `1.5.9. Swap`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_10_machine_network
`load_kb()` SHALL contain `7.1.tsr.1_5_10_machine_network` from `7_1_base_platform.toml`. Title SHALL be `1.5.10. Machine Network`.

description SHALL be:

The machine network CIDR defines the subnet used for node IP addresses.
This must not overlap with cluster or service networks and must have
sufficient address space for current and planned node scaling.

recommendation SHALL be:

Keep node INTERNAL-IP values inside the install-config machineNetwork CIDR, with no overlap of cluster or service networks. If node IPs fall outside the CIDR, plan addressing changes; do not patch Infrastructure to paper over it. Extract only the networking block — the ConfigMap can hold secrets.

verification SHALL be:

1. Print the machine network from install-config. Extract only the `networking:` block; the ConfigMap can contain trust bundles and BMC addresses:
   `oc get configmap cluster-config-v1 -n kube-system -o jsonpath='{.data.install-config}' | grep -A20 '^networking:'`
2. Confirm each node INTERNAL-IP falls within the declared machineNetwork CIDR:
   `oc get nodes -o wide`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

node addressing versus install-config machineNetwork

impact_detail SHALL be:

Node IPs outside the CIDR are a day-0 addressing problem. Do not patch Infrastructure to hide it.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_5_10_machine_network loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_10_machine_network`
- THEN the title is `1.5.10. Machine Network`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_11_fips
`load_kb()` SHALL contain `7.1.tsr.1_5_11_fips` from `7_1_base_platform.toml`. Title SHALL be `1.5.11. FIPS`.

description SHALL be:

FIPS 140-2 mode enforces use of validated cryptographic modules. FIPS must
be enabled at install time and cannot be toggled post-install. This check
verifies whether FIPS is active and consistent across nodes.

recommendation SHALL be:

Treat FIPS as install-time only. If the design required FIPS and `/proc/sys/crypto/fips_enabled` is 0, this is a rebuild. If FIPS is on and not required, leave it — turning it off is also a rebuild.

verification SHALL be:

1. Print the FIPS setting from install-config:
   `oc get configmap cluster-config-v1 -n kube-system -o jsonpath='{.data.install-config}' | grep -i '^fips:'`
2. Confirm FIPS status on each node:
   `oc debug node/<name> -- chroot /host cat /proc/sys/crypto/fips_enabled`
3. A value of `1` means FIPS is active. FIPS can only be set at install time.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster rebuild

impact_detail SHALL be:

FIPS is install-time. Turning it on or off is a rebuild, not a day-2 flag.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-fips_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-fips_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-fips_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-fips_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-fips_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-fips_installing-platform-agnostic`.

#### Scenario: 7.1.tsr.1_5_11_fips loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_11_fips`
- THEN the title is `1.5.11. FIPS`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_12_huge_pages
`load_kb()` SHALL contain `7.1.tsr.1_5_12_huge_pages` from `7_1_base_platform.toml`. Title SHALL be `1.5.12. Huge Pages`.

description SHALL be:

Huge pages provide large memory page allocations (2Mi or 1Gi) for performance-
sensitive workloads like databases and DPDK applications. Configuration must
match workload requirements without over-allocating node memory.

recommendation SHALL be:

Reserve huge pages only when the design needs DPDK or database pages, at the matching size (2Mi versus 1Gi). If pages are required but both columns are 0, reserve them through the documented Node/MCP path. Leftover unused reservation is accepted capacity cost or a planned MCP removal. Capacity 0/0 is N/A.

verification SHALL be:

1. Print the huge-page capacity per node (`status.capacity.hugepages-2Mi` and `hugepages-1Gi`). A value of `0` means none allocated:
   `oc get nodes -o custom-columns=NAME:.metadata.name,HUGE_2MI:.status.capacity.hugepages-2Mi,HUGE_1GI:.status.capacity.hugepages-1Gi`
2. Interpret the output:
      - Both `0`: huge pages are not configured. This is informational unless the design requires DPDK or database huge pages.
      - Non-zero: pages are reserved. Confirm the size (2Mi versus 1Gi) matches the workload requirement.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

MachineConfigPool that receives the hugepage reservation

impact_detail SHALL be:

Applying a desired MachineConfig drains and reboots nodes in that pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-managing-huge-pages_nodes-nodes-resources-configuring`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-nodes-managing-huge-pages_nodes-nodes-resources-configuring`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-nodes-managing-huge-pages_nodes-nodes-resources-configuring`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-nodes-managing-huge-pages_nodes-nodes-resources-configuring`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-nodes-managing-huge-pages_nodes-nodes-resources-configuring`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-nodes-managing-huge-pages_nodes-nodes-resources-configuring`.

#### Scenario: 7.1.tsr.1_5_12_huge_pages loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_12_huge_pages`
- THEN the title is `1.5.12. Huge Pages`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_13_gpu
`load_kb()` SHALL contain `7.1.tsr.1_5_13_gpu` from `7_1_base_platform.toml`. Title SHALL be `1.5.13. GPU`.

description SHALL be:

GPU nodes require the NVIDIA GPU Operator or equivalent for device plugin,
driver, and container toolkit management. Misconfigured GPU support causes
workload scheduling failures and resource waste.

recommendation SHALL be:

Install the GPU operator (or equivalent) and expose allocatable `nvidia.com/gpu` before scheduling GPU workloads. Empty grep plus empty allocatable is N/A unless the design called for GPUs. If GPUs are present but allocatable is empty, inspect the GPU operator pods.

verification SHALL be:

1. Check whether the GPU Operator subscription exists. Empty output means no GPU operator is installed, skip:
   `oc get subscription -A | grep gpu`
2. If present, print the allocatable GPU count per node:
   `oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.nvidia\.com/gpu}{"\n"}{end}'`
3. Confirm the GPU operator pods are Running:
   `oc get pods -n gpu-operator-resources`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

GPU operator and nvidia.com/gpu allocatable

impact_detail SHALL be:

Installing the GPU operator rolls operator and device-plugin pods. A node reboot may still be required for the driver firmware path.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#nvidia-gpu-architecture-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#nvidia-gpu-architecture-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#nvidia-gpu-architecture-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#nvidia-gpu-architecture-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#nvidia-gpu-architecture-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#nvidia-gpu-architecture-overview`.

#### Scenario: 7.1.tsr.1_5_13_gpu loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_13_gpu`
- THEN the title is `1.5.13. GPU`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_14_entropy
`load_kb()` SHALL contain `7.1.tsr.1_5_14_entropy` from `7_1_base_platform.toml`. Title SHALL be `1.5.14. Entropy`.

description SHALL be:

Sufficient entropy is required for cryptographic operations, TLS handshakes,
and certificate generation. Low entropy causes random number generation
blocking, slow TLS negotiations, and pod startup delays.

recommendation SHALL be:

Raise `entropy_avail` above 200 on every node (expect 3000+ on virtio-rng or RDRAND hosts). If entropy is low, enable virtio-rng or equivalent on the hypervisor and re-check. Do not ignore low entropy on nodes that terminate TLS.

verification SHALL be:

1. Print the available entropy on each node:
   `oc debug node/<name> -- chroot /host cat /proc/sys/kernel/random/entropy_avail`
2. **FAIL** when the value is below `200`. Investigate the entropy source.
3. Modern kernels with `virtio-rng` or `RDRAND` typically report `3000+`.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

hypervisor RNG (virtio-rng or equivalent)

impact_detail SHALL be:

Enabling virtio-rng is a host or VM change and may require a guest reboot. It is not an oc patch.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#security-hosts-vms-about_security-hardening`.

#### Scenario: 7.1.tsr.1_5_14_entropy loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_14_entropy`
- THEN the title is `1.5.14. Entropy`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_15_remote_health_reporting
`load_kb()` SHALL contain `7.1.tsr.1_5_15_remote_health_reporting` from `7_1_base_platform.toml`. Title SHALL be `1.5.15. Remote Health Reporting`.

description SHALL be:

Remote health reporting (Insights/Telemetry) sends anonymized cluster data
to Red Hat for proactive support and recommendations. Disabling it removes
access to Insights advisor recommendations and may affect support SLAs.

recommendation SHALL be:

Keep Insights Available and not Degraded so Telemetry can report, or leave it disabled only as documented accepted risk. If Degraded, check proxy/noProxy and whether remote health was disabled.

verification SHALL be:

1. Print the Insights ClusterOperator status:
   `oc get clusteroperator insights`
2. **PASS** when Insights is Available and not Degraded. If Degraded, check proxy settings and whether remote health reporting was disabled.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

Insights operator

impact_detail SHALL be:

Repairing Insights or documenting disabled telemetry does not reboot nodes. Proxy and noProxy fixes belong on the Proxy object.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`.

#### Scenario: 7.1.tsr.1_5_15_remote_health_reporting loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_15_remote_health_reporting`
- THEN the title is `1.5.15. Remote Health Reporting`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_16_project_self_provisioner_state
`load_kb()` SHALL contain `7.1.tsr.1_5_16_project_self_provisioner_state` from `7_1_base_platform.toml`. Title SHALL be `1.5.16. Project Self Provisioner State`.

description SHALL be:

The self-provisioner cluster role binding allows authenticated users to create
projects without admin approval. In production, this is often restricted to
prevent uncontrolled namespace proliferation.

recommendation SHALL be:

Clear `self-provisioners` subjects if project creation should be restricted. Leave `system:authenticated` bound only as accepted risk. Empty subjects means it is already disabled.

verification SHALL be:

1. List the subjects bound to the self-provisioners ClusterRoleBinding:
   `oc get clusterrolebinding self-provisioners -o jsonpath='{range .subjects[*]}{.kind}{"\t"}{.name}{"\t"}{.namespace}{"\n"}{end}'`
2. Empty output means self-provisioning is already disabled.
3. To restrict project creation, clear the subjects:
   `oc patch clusterrolebinding self-provisioners -p '{"subjects": null}'`
4. After clearing, project requests go through a controlled approval process.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

user project creation

impact_detail SHALL be:

Modifying the self-provisioners binding immediately changes who can create projects but does not affect existing namespaces or running workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/authentication_and_authorization/index#disabling-self-provisioning_understanding-authentication`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/authentication_and_authorization/index#disabling-self-provisioning_understanding-authentication`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/authentication_and_authorization/index#disabling-self-provisioning_understanding-authentication`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index#disabling-self-provisioning_understanding-authentication`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/authentication_and_authorization/index#disabling-self-provisioning_understanding-authentication`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/authentication_and_authorization/index#disabling-self-provisioning_understanding-authentication`.

#### Scenario: 7.1.tsr.1_5_16_project_self_provisioner_state loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_16_project_self_provisioner_state`
- THEN the title is `1.5.16. Project Self Provisioner State`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_17_authentication
`load_kb()` SHALL contain `7.1.tsr.1_5_17_authentication` from `7_1_base_platform.toml`. Title SHALL be `1.5.17. Authentication`.

description SHALL be:

Cluster authentication configuration determines identity providers, token
lifetimes, and access controls. Production clusters should use enterprise
identity providers and remove the default kubeadmin account.

recommendation SHALL be:

Configure and test an external identity provider, then verify that at least one externally authenticated user has functioning cluster-admin access before removing the kubeadmin secret. Do not remove kubeadmin while it remains the only verified administrative login, because removal is irreversible and can leave the cluster without recoverable administrative access. An HTPasswd provider or retained kubeadmin account may be acceptable for lab, temporary, or documented break-glass use.

verification SHALL be:

1. List the identity provider names and types on the OAuth object:
   `oc get oauth cluster -o jsonpath='{.spec.identityProviders[*].name}{"\t"}{.spec.identityProviders[*].type}{"\n"}'`
2. Print the access token maximum age if set:
   `oc get oauth cluster -o jsonpath='{.spec.tokenConfig.accessTokenMaxAgeSeconds}{"\n"}'`
3. Check whether the kubeadmin secret still exists:
   `oc get secret kubeadmin -n kube-system --ignore-not-found`
4. Only after an external identity provider is validated and a cluster-admin can log in through it, remove kubeadmin:
   `oc delete secret kubeadmin -n kube-system`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

authentication components

impact_detail SHALL be:

OAuth configuration changes roll authentication pods but do not reboot nodes or stop running workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/authentication_and_authorization/index#understanding-identity-provider`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/authentication_and_authorization/index#understanding-identity-provider`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/authentication_and_authorization/index#understanding-identity-provider`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index#understanding-identity-provider`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/authentication_and_authorization/index#understanding-identity-provider`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/authentication_and_authorization/index#understanding-identity-provider`.

#### Scenario: 7.1.tsr.1_5_17_authentication loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_17_authentication`
- THEN the title is `1.5.17. Authentication`
- AND `content_from` is empty


### Requirement: KB 7.1.tsr.1_5_18_security_context_constraints
`load_kb()` SHALL contain `7.1.tsr.1_5_18_security_context_constraints` from `7_1_base_platform.toml`. Title SHALL be `1.5.18. Security Context Constraints`.

description SHALL be:

Security Context Constraints control the actions pods can perform and what
resources they can access. Overly permissive SCCs (especially privileged or
anyuid) increase the attack surface of the cluster.

recommendation SHALL be:

Constrain tenant pods off `privileged` and `anyuid`, or document accepted risk. Stock platform pods may legitimately use them. Do not delete the privileged SCC.

verification SHALL be:

1. List the Security Context Constraints and their privilege flags:
   `oc get scc -o custom-columns=NAME:.metadata.name,PRIV:.allowPrivilegedContainer,ALLOWPRIVESC:.allowPrivilegeEscalation,RUNAS:.runAsUser.type`
2. List pods running under `privileged` or `anyuid`:
   `oc get pods -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,SCC:.metadata.annotations.openshift\.io/scc --no-headers | awk '$3=="privileged" || $3=="anyuid" {print}'`
3. Tenant pods using `privileged` or `anyuid` should be documented as accepted risk or constrained to a narrower SCC.

impact SHALL be:

workload-shift

impact_scope SHALL be:

tenant pods using privileged or anyuid

impact_detail SHALL be:

Revoking privileged SCC access often requires pod rollout or manifest changes so workloads can start under a less-privileged policy.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#security-context-constraints-about_configuring-internal-oauth`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#security-context-constraints-about_configuring-internal-oauth`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#security-context-constraints-about_configuring-internal-oauth`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#security-context-constraints-about_configuring-internal-oauth`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#security-context-constraints-about_configuring-internal-oauth`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#security-context-constraints-about_configuring-internal-oauth`.

#### Scenario: 7.1.tsr.1_5_18_security_context_constraints loads
- WHEN `get_entry` is called with `7.1.tsr.1_5_18_security_context_constraints`
- THEN the title is `1.5.18. Security Context Constraints`
- AND `content_from` is empty


### Requirement: KB 7.2.node.*.sysreserved
`load_kb()` SHALL contain `7.2.node.*.sysreserved` from `7_2_topology.toml`. Title SHALL be `Node systemReserved memory`.

The row SHALL be a glob pattern.

description SHALL be:

This check identifies high-memory nodes where the effective kubelet `systemReserved` memory allocation may be insufficient for the operating system and critical node services. `systemReserved` protects resources for system components such as CRI-O and the kubelet, reducing the risk that workload scheduling exhausts memory needed to keep the node functional. An empty oc get kubeletconfig result means no custom `KubeletConfig` CR has been created. It does not mean that system reservation is unset.

recommendation SHALL be:

For high-memory node pools, verify the effective `systemReserved` allocation and compare it with observed memory consumption by the operating system, kubelet, CRI-O, networking, monitoring, and other host-level services. If the effective reservation is inadequate, apply a targeted `KubeletConfig` to increase `systemReserved` memory or enable `autoSizingReserved`: true where supported. Do not create a custom reservation solely because no `KubeletConfig` CR exists. Make the change only after validating that the effective default reservation is insufficient for the node profile.

verification SHALL be:

1. List `KubeletConfig` CRs:
   `oc get kubeletconfig`
   `No resources found` is normal and does not mean systemReserved is unset. Without a KubeletConfig the kubelet uses defaults (`cpu=500m`, `memory=1Gi`) unless `systemReserved` or `autoSizingReserved: true` is set. Auto-sizing is a 4.21+ new-cluster feature; upgraded clusters keep the prior behavior.
2. Print the applied reservation:
   `oc get --raw /api/v1/nodes/<node>/proxy/configz | jq '{systemReserved: .kubeletconfig.systemReserved}'`
   Defaults are `cpu=500m` and `memory=1Gi`. Compare `memory` to total node RAM.
3. Create or update a `KubeletConfig` only if the reservation is insufficient. Set `machineConfigPoolSelector` for the pool and either enable `spec.autoSizingReserved: true` or pin `spec.kubeletConfig.systemReserved.memory`.
4. Size reserved memory to the node RAM. `1-2 GiB` for nodes with 64 GiB or more is guidance, not a mandated value; scale higher for larger nodes.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the targeted MachineConfigPool

impact_detail SHALL be:

`KubeletConfig` changes are applied through the Machine Config Operator, which drains and reboots affected nodes one at a time and shifts workloads per MCP rollout settings. On compact 3-node clusters where all nodes serve as both control-plane and worker, this affects 100% of cluster capacity.

`finding_group` SHALL be `node-system-reserved`.

`finding_group_title` SHALL be `Kubelet systemReserved missing on one or more nodes`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-resources-configuring-setting_nodes-nodes-resources-configuring`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-nodes-resources-configuring-setting_nodes-nodes-resources-configuring`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-nodes-resources-configuring-setting_nodes-nodes-resources-configuring`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-nodes-resources-configuring-setting_nodes-nodes-resources-configuring`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-nodes-resources-configuring-setting_nodes-nodes-resources-configuring`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-nodes-resources-configuring-setting_nodes-nodes-resources-configuring`.

#### Scenario: 7.2.node.*.sysreserved loads
- WHEN `get_entry` is called with `7.2.node.*.sysreserved`
- THEN the title is `Node systemReserved memory`
- AND `content_from` is empty


### Requirement: KB 7.2.etcd.members
`load_kb()` SHALL contain `7.2.etcd.members` from `7_2_topology.toml`. Title SHALL be `etcd member health`.

description SHALL be:

etcd requires a quorum of (n/2)+1 members to operate. A 3-member etcd cluster
tolerates the loss of 1 member. Degraded etcd members must be investigated
immediately because data loss or control plane instability can follow.

recommendation SHALL be:

Restore or replace an unhealthy etcd member only after a backup. A 3-member cluster can lose one; a second failure is an outage. Do not start replacement without a backup.

verification SHALL be:

1. List etcd pods and confirm each is Running on a distinct control-plane node:
   `oc get pods -n openshift-etcd -o wide`
2. Check endpoint health from any member:
   `oc -n openshift-etcd exec -c etcd etcd-<member> -- etcdctl endpoint health --cluster -w table`
3. If a member is unhealthy, take an etcd backup before replacing it.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and etcd members

impact_detail SHALL be:

Member recovery can require backup, replacement, or restore work on control-plane nodes and may reduce API availability while the cluster is stabilized.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#replacing-an-unhealthy-etcd-member`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/backup_and_restore/index#replacing-unhealthy-etcd-member`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#replacing-an-unhealthy-etcd-member`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#replacing-an-unhealthy-etcd-member`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#replacing-an-unhealthy-etcd-member`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#replacing-an-unhealthy-etcd-member`.

#### Scenario: 7.2.etcd.members loads
- WHEN `get_entry` is called with `7.2.etcd.members`
- THEN the title is `etcd member health`
- AND `content_from` is empty


### Requirement: KB 7.2.etcd.quorum
`load_kb()` SHALL contain `7.2.etcd.quorum` from `7_2_topology.toml`. Title SHALL be `etcd quorum`.

description SHALL be:

Quorum loss in etcd is a critical failure mode requiring manual recovery.
Always maintain an odd number of etcd members, typically 3 or 5. Never scale
etcd to 2 or 4 members.

recommendation SHALL be:

Keep an odd etcd member count (3 or 5). An even count (2 or 4) is a split-brain risk. If Available is False, restore a majority from backup; do not add even-numbered members.

verification SHALL be:

1. Print quorum conditions (`type`, `status`, `reason`):
   `oc get etcd cluster -o json | jq -c '.status.conditions[] | select(.type=="EtcdMembersAvailable" or .type=="EtcdMembersProgressing") | {type,status,reason}'`
2. Read the output:
      - `EtcdMembersAvailable` `True` with `reason=EtcdQuorate` means quorum is held (**PASS**).
      - `EtcdMembersAvailable` `False` means quorum is lost.
      - `EtcdMembersProgressing` `True` means a membership change is in flight. `False` is the expected stable state.
3. Confirm the member count is odd (3 or 5):
   `oc -n openshift-etcd exec -c etcd etcd-<member> -- etcdctl member list -w table`
4. If Available is False, restore a majority from backup. Do not add even-numbered members. Clustering guidance is in the reference for this check.
      Restore: https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/backup_and_restore/index#dr-restoring-cluster-state

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and etcd quorum

impact_detail SHALL be:

Quorum recovery is manual control-plane recovery work and can temporarily remove or reduce API availability until a majority of members is healthy.

Links SHALL be `default` -> `https://etcd.io/docs/latest/op-guide/clustering/`, `4.18` -> `https://etcd.io/docs/latest/op-guide/clustering/`, `4.19` -> `https://etcd.io/docs/latest/op-guide/clustering/`, `4.20` -> `https://etcd.io/docs/latest/op-guide/clustering/`, `4.21` -> `https://etcd.io/docs/latest/op-guide/clustering/`, `4.22` -> `https://etcd.io/docs/latest/op-guide/clustering/`.

#### Scenario: 7.2.etcd.quorum loads
- WHEN `get_entry` is called with `7.2.etcd.quorum`
- THEN the title is `etcd quorum`
- AND `content_from` is empty


### Requirement: KB 7.2.topo.master_az
`load_kb()` SHALL contain `7.2.topo.master_az` from `7_2_topology.toml`. Title SHALL be `Control plane availability zone distribution`.

description SHALL be:

Control plane nodes should be distributed across separate failure domains
(availability zones, racks, or hosts) to survive zone-level failures. All
control plane nodes in the same AZ creates a single point of failure for etcd
quorum and API availability.

recommendation SHALL be:

Validate the actual placement of all control-plane nodes across physical or logical failure domains—such as availability zones, racks, hypervisor hosts, or data-center fault domains—and distribute them so that the loss of any single domain does not remove etcd quorum or API availability. The absence of topology.kubernetes.io/zone labels means zone distribution cannot be verified from Kubernetes metadata. Do not add or modify topology labels merely to satisfy this check, because labels do not move nodes or improve resilience.

verification SHALL be:

1. List control-plane nodes with their zone label (topology.kubernetes.io/zone):
   `oc get nodes -l node-role.kubernetes.io/master -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone`
2. If all masters show the same zone or no zone, plan redistribution across actual failure domains.
3. Do not add labels without relocating machines; labels alone do not improve availability.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane machines and failure-domain placement

impact_detail SHALL be:

Redistributing control-plane nodes across failure domains typically replaces or migrates masters sequentially and should be performed in a planned window.

`finding_group` SHALL be `control-plane-az`.

`finding_group_title` SHALL be `Control plane availability zone distribution`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/machine_management/managing-control-plane-machines`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/machine_management/managing-control-plane-machines`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/machine_management/managing-control-plane-machines`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/machine_management/managing-control-plane-machines`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/machine_management/managing-control-plane-machines`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/machine_management/managing-control-plane-machines`.

#### Scenario: 7.2.topo.master_az loads
- WHEN `get_entry` is called with `7.2.topo.master_az`
- THEN the title is `Control plane availability zone distribution`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_1_consistency
`load_kb()` SHALL contain `7.2.tsr.2_1_consistency` from `7_2_topology.toml`. Title SHALL be `2.1. Consistency`.

description SHALL be:

Section overview for cluster consistency checks. Validates that all nodes in
the cluster run the same OCP and OS releases, preventing version skew that can
cause unpredictable behaviour during upgrades or day-2 operations.

recommendation SHALL be:

This section is a section index. Bring every node to the same OCP and OS release before the next upgrade. Use the OCP-release and OS-release children for scored recommendations.

verification SHALL be:

1. List node versions and OS image:
   `oc get nodes -o wide`
2. Check `MachineConfigPool` sync. UPDATED True, UPDATING False, DEGRADED False means the pool is idle:
   `oc get machineconfigpool`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#architecture-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#architecture-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#architecture-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#architecture-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#architecture-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#architecture-overview`.

#### Scenario: 7.2.tsr.2_1_consistency loads
- WHEN `get_entry` is called with `7.2.tsr.2_1_consistency`
- THEN the title is `2.1. Consistency`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_1_1_consistent_ocp_release
`load_kb()` SHALL contain `7.2.tsr.2_1_1_consistent_ocp_release` from `7_2_topology.toml`. Title SHALL be `2.1.1. Consistent OCP Release`.

description SHALL be:

All nodes should report the same OpenShift release version. Version skew across
nodes indicates an incomplete or stalled upgrade and can cause workload
scheduling failures, operator degradation, and API incompatibilities.

recommendation SHALL be:

Bring every kubelet to one VERSION cluster-wide. If they differ, inspect paused or degraded MCPs before unpausing — unpausing drains remaining nodes.

verification SHALL be:

1. Compare kubelet versions across nodes:
   `oc get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion`
2. If versions differ, check `MachineConfigPool` rollout status:
   `oc get machineconfigpool`
3. Resume a stalled pool only after confirming the pause was not intentional:
   `oc patch machineconfigpool/<pool> --type merge -p '{"spec":{"paused":false}}'`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the unpaused MachineConfigPool

impact_detail SHALL be:

Unpausing an MCP lets a pending MachineConfig or upgrade drain and reboot remaining nodes. Discovery commands alone do not change the cluster.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#architecture-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#architecture-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#architecture-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#architecture-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#architecture-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#architecture-overview`.

#### Scenario: 7.2.tsr.2_1_1_consistent_ocp_release loads
- WHEN `get_entry` is called with `7.2.tsr.2_1_1_consistent_ocp_release`
- THEN the title is `2.1.1. Consistent OCP Release`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_1_2_consistent_os_release
`load_kb()` SHALL contain `7.2.tsr.2_1_2_consistent_os_release` from `7_2_topology.toml`. Title SHALL be `2.1.2. Consistent OS Release`.

description SHALL be:

All nodes should run the same RHCOS (or RHEL) version. OS-level skew can
introduce kernel, cgroup, or container-runtime inconsistencies that affect
workload stability and complicate troubleshooting.

recommendation SHALL be:

Bring every node to one OS-image column. Mixed RHCOS/RHEL workers or mixed kernels complicate cgroup and runtime troubleshooting; treat OS skew as a stalled MCP rollout.

verification SHALL be:

1. List OS image and kernel per node:
   `oc get nodes -o custom-columns=NAME:.metadata.name,OS:.status.nodeInfo.osImage,KERNEL:.status.nodeInfo.kernelVersion`
2. If OS versions differ, check `MachineConfigPool` rollout state:
   `oc get machineconfigpool -o wide`
3. A paused or degraded pool blocks the OS update.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the drifted MachineConfigPool

impact_detail SHALL be:

Completing a stalled kubelet or machine-config rollout drains and reboots lagging nodes one at a time. On compact 3-node clusters where all nodes serve as both control-plane and worker, this affects 100% of cluster capacity.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#architecture-platform-introduction_architecture-rhcos`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#architecture-platform-introduction_architecture-rhcos`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#architecture-platform-introduction_architecture-rhcos`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#architecture-platform-introduction_architecture-rhcos`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#architecture-platform-introduction_architecture-rhcos`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#architecture-platform-introduction_architecture-rhcos`.

#### Scenario: 7.2.tsr.2_1_2_consistent_os_release loads
- WHEN `get_entry` is called with `7.2.tsr.2_1_2_consistent_os_release`
- THEN the title is `2.1.2. Consistent OS Release`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_2_high_availability
`load_kb()` SHALL contain `7.2.tsr.2_2_high_availability` from `7_2_topology.toml`. Title SHALL be `2.2. High Availability`.

description SHALL be:

Section overview for high availability checks. Evaluates control plane
resiliency including master node count, failure-domain distribution, and load
balancer redundancy to ensure the cluster can survive component failures.

recommendation SHALL be:

This section is a section index. Use master count, zone labels, and API/ingress load-balancer redundancy for scored recommendations.

verification SHALL be:

1. Check control-plane readiness. The `STATUS` column shows Ready or NotReady:
   `oc get nodes -l node-role.kubernetes.io/master`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#about-control-planes_architecture-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#about-control-planes_architecture-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#about-control-planes_architecture-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#about-control-planes_architecture-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#about-control-planes_architecture-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#about-control-planes_architecture-overview`.

#### Scenario: 7.2.tsr.2_2_high_availability loads
- WHEN `get_entry` is called with `7.2.tsr.2_2_high_availability`
- THEN the title is `2.2. High Availability`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_2_1_number_of_master_nodes
`load_kb()` SHALL contain `7.2.tsr.2_2_1_number_of_master_nodes` from `7_2_topology.toml`. Title SHALL be `2.2.1. Number of Master Nodes`.

description SHALL be:

A production OpenShift cluster requires 3 control plane nodes to maintain etcd
quorum and tolerate a single node failure. Bare-metal clusters may use up to 5
control plane nodes. Fewer than 3 masters risks quorum loss.

recommendation SHALL be:

Run production HA with three control-plane nodes (five is the documented bare-metal maximum). Document SNO and compact if that topology was chosen on purpose rather than treating a count of 1, or a 3-node compact cluster, as a defect.

verification SHALL be:

1. Count master nodes:
   `oc get nodes -l node-role.kubernetes.io/master --no-headers | wc -l`
2. If the count is not 3 (or 5 on bare metal), confirm the intended topology before flagging it.
3. Verify etcd member placement matches the master count:
   `oc get pods -n openshift-etcd -o wide`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control-plane membership

impact_detail SHALL be:

Growing to three or five masters is planned control-plane work. Documented SNO or compact stays none and is not treated as a defect.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#about-control-planes_architecture-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#about-control-planes_architecture-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#about-control-planes_architecture-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#about-control-planes_architecture-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#about-control-planes_architecture-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#about-control-planes_architecture-overview`.

#### Scenario: 7.2.tsr.2_2_1_number_of_master_nodes loads
- WHEN `get_entry` is called with `7.2.tsr.2_2_1_number_of_master_nodes`
- THEN the title is `2.2.1. Number of Master Nodes`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_2_2_master_av_zone_labels
`load_kb()` SHALL contain `7.2.tsr.2_2_2_master_av_zone_labels` from `7_2_topology.toml`. Title SHALL be `2.2.2. Master AV Zone Labels`.

description SHALL be:

Control plane nodes should carry topology.kubernetes.io/zone labels and be
distributed across at least 2 (ideally 3) distinct availability zones. Missing
or identical zone labels indicate a single-zone control plane vulnerable to
zone-level outages.

recommendation SHALL be:

Validate the actual placement of all control-plane nodes across physical or logical failure domains—such as availability zones, racks, hypervisor hosts, or data-center fault domains—and distribute them so that the loss of any single domain does not remove etcd quorum or API availability. The absence of topology.kubernetes.io/zone labels means zone distribution cannot be verified from Kubernetes metadata. Do not add or modify topology labels merely to satisfy this check, because labels do not move nodes or improve resilience.

verification SHALL be:

1. List zone labels on master nodes (topology.kubernetes.io/zone):
   `oc get nodes -l node-role.kubernetes.io/master -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone`
2. Missing or identical values mean zone distribution cannot be confirmed from metadata alone.
3. If all masters share one failure domain, plan machine redistribution. Adding labels without moving machines does not improve availability.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

control-plane node labels

impact_detail SHALL be:

Adding topology labels does not drain nodes. Relocating control-plane machines across zones is a separate maintenance-window activity.

`finding_group` SHALL be `control-plane-az`.

`finding_group_title` SHALL be `Control plane availability zone distribution`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#about-control-planes_architecture-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#about-control-planes_architecture-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#about-control-planes_architecture-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#about-control-planes_architecture-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#about-control-planes_architecture-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#about-control-planes_architecture-overview`.

#### Scenario: 7.2.tsr.2_2_2_master_av_zone_labels loads
- WHEN `get_entry` is called with `7.2.tsr.2_2_2_master_av_zone_labels`
- THEN the title is `2.2.2. Master AV Zone Labels`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_2_3_haproxy_ha
`load_kb()` SHALL contain `7.2.tsr.2_2_3_haproxy_ha` from `7_2_topology.toml`. Title SHALL be `2.2.3. HAProxy HA`.

description SHALL be:

The API and ingress load balancers (commonly HAProxy) must be highly available.
A single load balancer is a single point of failure for all cluster traffic.
HA is typically achieved via keepalived/VRRP or external load balancer
redundancy.

recommendation SHALL be:

Ensure the API and ingress entry points have a tested high-availability design with no single load-balancer host or appliance that can interrupt cluster access. For externally managed load balancers, verify redundant instances for API traffic on 6443 and ingress traffic on 80/443. For bare-metal IPI and similar on-premises IPI deployments, do not infer a single point of failure from a SingleReplica value alone: OpenShift commonly provides API and ingress VIP failover through keepalived/VRRP, with HAProxy serving traffic on the current VIP owner. Validate the actual keepalived and HAProxy static-pod health.

verification SHALL be:

1. Print IngressController replica counts:
   `oc get ingresscontroller default -n openshift-ingress-operator -o custom-columns=NAME:.metadata.name,SPEC:.spec.replicas,AVAILABLE:.status.availableReplicas`
2. Both columns at 2 or above means HA. `1` is SingleReplica. `<none>` in AVAILABLE means the operator has not reported status yet.
3. List router pods:
   `oc get pods -n openshift-ingress`
4. Check the platform load-balancer implementation: bare-metal IPI uses keepalived/HAProxy in openshift-kni-infra; vSphere IPI uses openshift-vsphere-infra; external LBs need out-of-cluster validation.
   `oc get pods -n openshift-kni-infra`
   `oc get pods -n openshift-vsphere-infra`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

API and ingress load-balancer infrastructure

impact_detail SHALL be:

Adding redundant load balancers or VIPs can interrupt 6443, 80, and 443 until failover is proven.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`.

#### Scenario: 7.2.tsr.2_2_3_haproxy_ha loads
- WHEN `get_entry` is called with `7.2.tsr.2_2_3_haproxy_ha`
- THEN the title is `2.2.3. HAProxy HA`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_3_scalability
`load_kb()` SHALL contain `7.2.tsr.2_3_scalability` from `7_2_topology.toml`. Title SHALL be `2.3. Scalability`.

description SHALL be:

Section overview for scalability checks. Assesses whether the cluster's node
count, pod density, and routing configuration are within tested limits and
scaled appropriately for the workload.

recommendation SHALL be:

This section is a section index. Use node count, pod density, and router capacity for scored recommendations.

verification SHALL be:

1. Count cluster nodes:
   `oc get nodes --no-headers | wc -l`
2. Count total pods cluster-wide:
   `oc get pods -A --no-headers | wc -l`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`.

#### Scenario: 7.2.tsr.2_3_scalability loads
- WHEN `get_entry` is called with `7.2.tsr.2_3_scalability`
- THEN the title is `2.3. Scalability`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_3_1_sdn_number_of_nodes
`load_kb()` SHALL contain `7.2.tsr.2_3_1_sdn_number_of_nodes` from `7_2_topology.toml`. Title SHALL be `2.3.1. SDN Number of Nodes`.

description SHALL be:

The software-defined network plugin has tested scalability limits on the number
of nodes it can manage. Exceeding these limits can cause increased API server
load, flow table exhaustion, and network programming delays.

recommendation SHALL be:

Stay at or below the OVN-Kubernetes tested limit of 2,000 nodes. Crossing that is API load, flow-table pressure, and network-programming delay. OpenShift SDN was removed in 4.17 and does not apply to current releases.

verification SHALL be:

1. Count cluster nodes:
   `oc get nodes --no-headers | wc -l`
2. Identify the active network plugin:
   `oc get network.config cluster -o jsonpath='{.spec.networkType}'`
3. Compare the node count to published scalability limits for that plugin. If approaching the limit, plan scale-out rather than adding more nodes.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster scale or split

impact_detail SHALL be:

Staying at or below 2,000 OVN nodes may mean not adding more, or splitting the estate. That is capacity planning, not a kubelet tweak.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`.

#### Scenario: 7.2.tsr.2_3_1_sdn_number_of_nodes loads
- WHEN `get_entry` is called with `7.2.tsr.2_3_1_sdn_number_of_nodes`
- THEN the title is `2.3.1. SDN Number of Nodes`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_3_2_sdn_number_of_pods
`load_kb()` SHALL contain `7.2.tsr.2_3_2_sdn_number_of_pods` from `7_2_topology.toml`. Title SHALL be `2.3.2. SDN Number of Pods`.

description SHALL be:

Each node has a maximum pod capacity (default 250) and the cluster has overall
pod density limits tied to the SDN plugin. Exceeding pod limits causes
scheduling failures and degrades network performance due to iptables/OVS flow
table pressure.

recommendation SHALL be:

Keep bound-pod counts at or below each node's allocatable PODS column (kubelet default 250). Scheduling past it fails; running near it stresses OVS flow tables. Compare per node, not to a cluster-wide total.

verification SHALL be:

1. Show allocatable pods per node:
   `oc get nodes -o custom-columns=NAME:.metadata.name,PODS:.status.allocatable.pods`
2. Count running pods per node:
   `oc get pods -A --no-headers -o custom-columns=NODE:.spec.nodeName | awk '$1 != "" && $1 != "<none>"' | sort | uniq -c | sort -rn`
   Rows showing `<none>` are Pending or unschedulable pods.
3. Check `maxPods` in `KubeletConfig`. `No resources found` means the default of 250 applies:
   `oc get kubeletconfig -o custom-columns=NAME:.metadata.name,MAXPODS:.spec.kubeletConfig.maxPods`

impact SHALL be:

workload-shift

impact_scope SHALL be:

pods on nodes near allocatable PODS

impact_detail SHALL be:

Reducing density or spreading pods reschedules those workloads. Adding nodes is a maintenance window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#recommended-performance-scale-practices_recommended-performance-scale-practices`.

#### Scenario: 7.2.tsr.2_3_2_sdn_number_of_pods loads
- WHEN `get_entry` is called with `7.2.tsr.2_3_2_sdn_number_of_pods`
- THEN the title is `2.3.2. SDN Number of Pods`
- AND `content_from` is empty


### Requirement: KB 7.2.tsr.2_3_3_routing_scaling
`load_kb()` SHALL contain `7.2.tsr.2_3_3_routing_scaling` from `7_2_topology.toml`. Title SHALL be `2.3.3. Routing Scaling`.

description SHALL be:

Ingress router capacity must scale with the number of Routes and traffic
volume. Undersized router deployments cause connection queuing, increased
latency, and dropped connections under load.

recommendation SHALL be:

Scale IngressController replicas to Route count and traffic. Undersized replicas queue connections and drop under load. Scaling adds or removes router pods; it does not drain nodes.

verification SHALL be:

1. Show IngressController replica counts:
   `oc get ingresscontroller default -n openshift-ingress-operator -o custom-columns=NAME:.metadata.name,SPEC:.spec.replicas,AVAILABLE:.status.availableReplicas`
2. Check router pod placement across nodes:
   `oc get pods -n openshift-ingress -o wide`
3. Count total Route objects:
   `oc get routes -A --no-headers | wc -l`
4. Scale replicas if the count is too low for the Route load:
   `oc patch ingresscontroller default -n openshift-ingress-operator --type merge -p '{"spec":{"replicas":<N>}}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

ingress router pods

impact_detail SHALL be:

Scaling the IngressController replica count adds or removes router pods without disrupting existing connections.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`.

#### Scenario: 7.2.tsr.2_3_3_routing_scaling loads
- WHEN `get_entry` is called with `7.2.tsr.2_3_3_routing_scaling`
- THEN the title is `2.3.3. Routing Scaling`
- AND `content_from` is empty


### Requirement: KB 7.2.mcp.*
`load_kb()` SHALL contain `7.2.mcp.*` from `7_2_topology.toml`. Title SHALL be `MachineConfigPool`.

The row SHALL be a glob pattern.

description SHALL be:

This check is the named `MachineConfigPool` degraded, updating, paused, and machine-count posture. `Updated=False` with matching `updatedMachineCount` and `readyMachineCount` and `spec.paused=true` is a pause hold, not a missing node count. Degraded or mismatched counts are a rollout defect.

recommendation SHALL be:

Bring the named `MachineConfigPool` to a stable rollout: `Degraded=False`, not stuck `Updating`, and `spec.paused=false` unless a documented canary or change window requires a short pause. A paused pool with matching machine counts is an intentional hold, not a missing update. Unpause only after that window; the Machine Config Operator then drains and often reboots remaining nodes, and a long pause can block kube-apiserver-to-kubelet CA rotation so `oc debug` and `oc exec` fail. If machine counts do not match or `Degraded` is True, inspect pool conditions and Machine Config Daemon logs on the affected nodes before changing `paused` or `maxUnavailable`.

verification SHALL be:

1. List each pool name, paused flag, and machine counts. Paused true with matching counts is the pause case. Mismatched counts or Degraded need investigation.
   `oc get mcp`
2. Print paused on each pool. True needs a documented window or unpause.
   `oc get mcp -o custom-columns=NAME:.metadata.name,PAUSED:.spec.paused`
3. If Degraded is True, print the condition reason and message.
   `oc describe mcp <pool>`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the named MachineConfigPool

impact_detail SHALL be:

Unpausing or repairing a pool lets the MCO drain and reboot nodes in that pool.

`finding_group` SHALL be `mcp-paused`.

`finding_group_title` SHALL be `MachineConfigPool paused`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/machine_configuration/index#understanding-the-machine-config-operator`.

#### Scenario: 7.2.mcp.* loads
- WHEN `get_entry` is called with `7.2.mcp.*`
- THEN the title is `MachineConfigPool`
- AND `content_from` is empty


### Requirement: KB 7.3.version
`load_kb()` SHALL contain `7.3.version` from `7_3_components.toml`. Title SHALL be `Cluster version health`.

description SHALL be:

ClusterVersion conditions indicate whether the cluster is in a healthy upgrade
state. Progressing, Failing, or `RetrievedUpdates=False` conditions indicate
upgrade-path issues that require investigation before planning the next update.

recommendation SHALL be:

Stop the next update until ClusterVersion conditions are quiet and the unhealthy-operator grep is header-only. A stuck or failing condition is a stop. Read conditions first, then CVO logs, then plan the window.

verification SHALL be:

1. Print ClusterVersion conditions only:
   `oc get clusterversion version -o jsonpath='{range .status.conditions[*]}{.type}={.status} reason={.reason}{"\n"}{end}'`
2. If Progressing is stuck or Failing is True, review the cluster-version-operator logs:
   `oc -n openshift-cluster-version logs deployment/cluster-version-operator`
3. List only unhealthy ClusterOperators:
   `oc get co | grep -v 'True.*False.*False'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster upgrade and CVO recovery

impact_detail SHALL be:

A stuck or failing ClusterVersion is a stop. Unblocking it usually means a planned update or CVO recovery window, which rolls operators, nodes, and workloads over time.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#understanding-clusterversion-conditiontypes_understanding-openshift-updates`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#understanding-clusterversion-conditiontypes_understanding-openshift-updates`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#understanding-clusterversion-conditiontypes_understanding-openshift-updates`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#understanding-clusterversion-conditiontypes_understanding-openshift-updates`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#understanding-clusterversion-conditiontypes_understanding-openshift-updates`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#understanding-clusterversion-conditiontypes_understanding-openshift-updates`.

#### Scenario: 7.3.version loads
- WHEN `get_entry` is called with `7.3.version`
- THEN the title is `Cluster version health`
- AND `content_from` is empty


### Requirement: KB 7.3.co.kube-apiserver
`load_kb()` SHALL contain `7.3.co.kube-apiserver` from `7_3_components.toml`. Title SHALL be `Cluster Operator: kube-apiserver`.

description SHALL be:

The kube-apiserver operator manages the Kubernetes API server on all control
plane nodes. When degraded, API availability is impaired — affecting all
cluster operations including workload scheduling and oc/kubectl commands.

recommendation SHALL be:

Bring kube-apiserver to `Available=True`, `Progressing=False`, `Degraded=False`. Treat a degraded API as an incident: read conditions, then logs and events. Do not delete the static pod until you know why it degraded.

verification SHALL be:

1. Confirm kube-apiserver (`Available=True`, `Progressing=False`, `Degraded=False`):
   `oc get co kube-apiserver --no-headers | awk '{print ($3=="True" && $4=="False" && $5=="False"?"PASS":"FAIL"), $0}'`
2. If the operator is not healthy, print conditions:
   `oc get co kube-apiserver -o jsonpath='{range .status.conditions[*]}{.type}={.status} reason={.reason}{"\n"}{end}'`
3. Inspect API server logs:
   `oc -n openshift-kube-apiserver logs kube-apiserver-<node> -c kube-apiserver`
4. Check events:
   `oc get events -n openshift-kube-apiserver --sort-by=.lastTimestamp`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane API

impact_detail SHALL be:

Restoring a degraded kube-apiserver can restart control-plane static pods and may reduce API availability until the operator is healthy.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#control-plane`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#control-plane`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#control-plane`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#control-plane`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#control-plane`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#control-plane`.

#### Scenario: 7.3.co.kube-apiserver loads
- WHEN `get_entry` is called with `7.3.co.kube-apiserver`
- THEN the title is `Cluster Operator: kube-apiserver`
- AND `content_from` is empty


### Requirement: KB 7.3.co.*
`load_kb()` SHALL contain `7.3.co.*` from `7_3_components.toml`. Title SHALL be `Cluster Operator`.

The row SHALL be a glob pattern.

description SHALL be:

ClusterOperators provide core cluster functionality. When a cluster operator is
degraded or unavailable, one of its managed components is not functioning as
intended and cluster stability or supportability may be impaired.

recommendation SHALL be:

Bring every ClusterOperator to `Available=True`, `Progressing=False`, `Degraded=False`. Name the failing condition, then inspect that operator namespace. Fix the dependency (certificates, DNS, storage, quota) before you restart the operand.

verification SHALL be:

1. Describe the affected cluster operator to identify the failing conditions:
   `oc describe clusteroperator <name>`
2. Review the operator deployment and pods in the affected namespace:
   `oc get pods -n <operator-ns>`
3. Inspect the relevant operator pod logs for the root cause:
   `oc logs -n <operator-ns> <pod>`
4. Review recent namespace events to correlate certificate, dependency, networking, or resource issues:
   `oc get events -n <operator-ns> --sort-by=.lastTimestamp`
5. Resolve the underlying dependency or infrastructure issue before restarting operator-managed components.

impact SHALL be:

workload-shift

impact_scope SHALL be:

the degraded operator's operands

impact_detail SHALL be:

Fixing the named dependency then reconciling the operator rolls its pods. It does not reboot nodes by itself; Machine Config, etcd, and network children can require a heavier window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#control-plane`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#control-plane`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#control-plane`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#control-plane`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#control-plane`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#control-plane`.

#### Scenario: 7.3.co.* loads
- WHEN `get_entry` is called with `7.3.co.*`
- THEN the title is `Cluster Operator`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_2_1_platform_operators
`load_kb()` SHALL contain `7.3.tsr.3_2_1_platform_operators` from `7_3_components.toml`. Title SHALL be `TSR platform operators`.

description SHALL be:

Platform operators (ClusterOperators) provide core cluster functionality. Any
degraded or unavailable operator indicates a component that is not functioning
as intended and may affect cluster stability or supportability.

recommendation SHALL be:

Clear the platform-operator exception list. Empty besides the header is healthy. Read conditions and namespace events for each remaining name rather than restarting operators in bulk.

verification SHALL be:

1. Review degraded operators to find operators not in `Available=True`, `Progressing=False`, `Degraded=False` state:
   `oc get co | grep -v 'True.*False.*False'`
2. Inspect each degraded operator's conditions and namespace events.
3. Common remediation involves restarting the operator pod or resolving underlying resource issues (certificates, networking, storage).

impact SHALL be:

workload-shift

impact_scope SHALL be:

named platform operator namespaces

impact_detail SHALL be:

Clearing a degraded platform operator rolls that operator's pods after the dependency is fixed. It does not reboot nodes by itself.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#control-plane`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#control-plane`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#control-plane`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#control-plane`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#control-plane`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#control-plane`.

#### Scenario: 7.3.tsr.3_2_1_platform_operators loads
- WHEN `get_entry` is called with `7.3.tsr.3_2_1_platform_operators`
- THEN the title is `TSR platform operators`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_3_custom_resource_definitions
`load_kb()` SHALL contain `7.3.tsr.3_3_custom_resource_definitions` from `7_3_components.toml`. Title SHALL be `TSR custom resource definitions`.

description SHALL be:

This check identifies CRDs that retain an OLM ownership label but whose owning Operator no longer has a Succeeded `ClusterServiceVersion` (CSV). Such CRDs can be remnants of a previous Operator installation or uninstall, but their presence alone does not prove they are safe to remove. This check does not assess overall CRD count, webhook health, or unused namespaces; those are evaluated separately. A result with no orphaned OLM-owned CRDs is **PASS**.

recommendation SHALL be:

For each identified CRD, first confirm that the owning Operator is intentionally absent and inventory all custom-resource instances across the cluster. If no instances remain, back up the CRD definition and verify no remaining workloads, automation, integrations, or planned reinstall depend on it before deleting the CRD. Do not delete a CRD that still has live instances because deleting a CRD removes its API endpoint and deletes all custom objects of that type. Treat excessive live CRD count as a separate API-discovery and lifecycle-management issue; it is not justification for deleting CRDs that are still in use.

verification SHALL be:

1. Print OLM owner labels on CRDs. If no labels are found, OLM ownership is not in use:
   `oc get crd -o json | jq -r '.items[] | (.metadata.labels // {}) | keys[]' | awk '/^operators.coreos.com\//{count[$1]++} END{if(length(count)==0) print "INFO n/a-olm-owner"; else for (owner in count) print "INFO", "COUNT="count[owner], "OWNER="owner}'`
2. Print live CSVs. PHASE is on the stock table. If no CSVs exist, none are installed:
   `oc get csv -A 2>&1 | awk '/No resources found/{print "INFO n/a-csv"; seen=1} seen{next} {print}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

API schema and any workloads, automation, or integrations that still use the CRD

impact_detail SHALL be:

Deleting a CRD that still has dependents can cause unpredictable results. At minimum it is a workload shift: the CRD API is removed and all custom objects of that type are deleted. Confirm the owning Operator is gone and that no instances or dependents remain before deletion.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/operators/index#crd-managing-resources-from-crds`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/operators/index#crd-managing-resources-from-crds`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/operators/index#crd-managing-resources-from-crds`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/operators/index#crd-managing-resources-from-crds`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/operators/index#crd-managing-resources-from-crds`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/operators/index#crd-managing-resources-from-crds`.

#### Scenario: 7.3.tsr.3_3_custom_resource_definitions loads
- WHEN `get_entry` is called with `7.3.tsr.3_3_custom_resource_definitions`
- THEN the title is `TSR custom resource definitions`
- AND `content_from` is empty


### Requirement: KB 7.3.crds
`load_kb()` SHALL contain `7.3.crds` from `7_3_components.toml`. Title SHALL be `Custom resource definitions`.

description SHALL be:

High CRD count can impact API server start time and list/watch performance.
A count above 500 is treated as a warning (internal heuristic, not a vendor maximum).
Orphaned CRDs from uninstalled operators are a separate finding.

recommendation SHALL be:

If CRD count is over 500, clean orphan CRDs rather than deleting live CRDs. CRD count is an API-discovery load signal, not a vendor maximum.

verification SHALL be:

1. Count CRDs:
   `oc get crd --no-headers | wc -l`
2. Engine **WARNING** is greater than 500 (internal heuristic, not a published cluster maximum).

impact SHALL be:

workload-shift

impact_scope SHALL be:

orphaned CRDs and leftover custom objects

impact_detail SHALL be:

Deleting a CRD that still has dependents can cause unpredictable results. At minimum it is a workload shift: the CRD API is removed and all custom objects of that type are deleted. Confirm the owning Operator is gone and that no instances or dependents remain before deletion.

Links SHALL be `default` -> `https://docs.openshift.com/container-platform/latest/scalability_and_performance/planning-your-environment-according-to-object-maximums.html`, `4.18` -> `https://docs.openshift.com/container-platform/4.18/scalability_and_performance/planning-your-environment-according-to-object-maximums.html`, `4.19` -> `https://docs.openshift.com/container-platform/4.19/scalability_and_performance/planning-your-environment-according-to-object-maximums.html`, `4.20` -> `https://docs.openshift.com/container-platform/4.20/scalability_and_performance/planning-your-environment-according-to-object-maximums.html`, `4.21` -> `https://docs.openshift.com/container-platform/4.21/scalability_and_performance/planning-your-environment-according-to-object-maximums.html`, `4.22` -> `https://docs.openshift.com/container-platform/4.22/scalability_and_performance/planning-your-environment-according-to-object-maximums.html`.

#### Scenario: 7.3.crds loads
- WHEN `get_entry` is called with `7.3.crds`
- THEN the title is `Custom resource definitions`
- AND `content_from` is empty


### Requirement: KB 7.3.deprecated_apis
`load_kb()` SHALL contain `7.3.deprecated_apis` from `7_3_components.toml`. Title SHALL be `Deprecated APIs`.

description SHALL be:

Clusters cannot upgrade past the version where a deprecated API is removed if
active usage still exists. Use `oc get apirequestcounts` to identify callers
and update clients before the next minor upgrade.

recommendation SHALL be:

Change clients — manifests, Helm charts, and Operators — off any API the next minor will remove. Identify callers from APIRequestCount. Do not try to keep the old API on the apiserver.

verification SHALL be:

1. Identify which clients are using deprecated APIs:
   `oc get apirequestcounts`
2. Update manifests, Helm charts, and Operators to use current API versions.

impact SHALL be:

workload-shift

impact_scope SHALL be:

manifests, Helm charts, and Operators still on the removed API

impact_detail SHALL be:

Changing clients off an API the next minor will remove triggers application or Operator rollouts. The old API cannot be kept on the apiserver.

Links SHALL be `default` -> `https://kubernetes.io/docs/reference/using-api/deprecation-guide/`, `4.18` -> `https://kubernetes.io/docs/reference/using-api/deprecation-guide/`, `4.19` -> `https://kubernetes.io/docs/reference/using-api/deprecation-guide/`, `4.20` -> `https://kubernetes.io/docs/reference/using-api/deprecation-guide/`, `4.21` -> `https://kubernetes.io/docs/reference/using-api/deprecation-guide/`, `4.22` -> `https://kubernetes.io/docs/reference/using-api/deprecation-guide/`.

#### Scenario: 7.3.deprecated_apis loads
- WHEN `get_entry` is called with `7.3.deprecated_apis`
- THEN the title is `Deprecated APIs`
- AND `content_from` is empty


### Requirement: KB 7.3.network.plugin
`load_kb()` SHALL contain `7.3.network.plugin` from `7_3_components.toml`. Title SHALL be `Cluster network plugin`.

description SHALL be:

OVNKubernetes is the recommended network plugin for current OCP releases.
OpenShiftSDN is deprecated and must be migrated before advancing beyond its
supported lifecycle.

recommendation SHALL be:

If the CNI is still OpenShiftSDN, run the documented live migration in a maintenance window before a 4.17+ upgrade. Do not day-2 edit the Network CR to change type. Keep the network operator healthy on the live plugin.

verification SHALL be:

1. Confirm the active network plugin:
   `oc get network.config cluster -o jsonpath='{.spec.networkType}'`
2. Confirm the network ClusterOperator:
   `oc get co network --no-headers | awk '{print ($3=="True" && $4=="False" && $5=="False"?"PASS":"FAIL"), $0}'`
3. Migrate from OpenShiftSDN to OVNKubernetes before upgrading to OCP 4.17 -- SDN support is removed in 4.17 and later.
4. Follow the live migration guide and validate the cluster network operator state before scheduling the upgrade window.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster networking and node data plane

impact_detail SHALL be:

Network-plugin migration changes cluster networking behavior and can disrupt pod and service traffic if not executed in a planned maintenance window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#sdn-support-removal`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#sdn-support-removal`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#sdn-support-removal`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#sdn-support-removal`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#sdn-support-removal`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#sdn-support-removal`.

#### Scenario: 7.3.network.plugin loads
- WHEN `get_entry` is called with `7.3.network.plugin`
- THEN the title is `Cluster network plugin`
- AND `content_from` is empty


### Requirement: KB 7.3.registry.state
`load_kb()` SHALL contain `7.3.registry.state` from `7_3_components.toml`. Title SHALL be `Internal registry state`.

description SHALL be:

The internal image registry is required for builds and ImageStream-based
deployments unless the cluster uses only an external registry. `Removed` means
the Operator tore the instance down. `Managed` means the Operator reconciles
the registry. `Unmanaged` means the Operator ignores config; a user-managed
registry with user-provided storage is valid. `spec.storage.managementState`
is a separate field: `Unmanaged` storage is user-provided backend, not Operator
state.

recommendation SHALL be:

Confirm whether the cluster is intended to use the OpenShift integrated image registry or an external registry service. If the integrated registry is required for image builds, ImageStreams, internal image distribution, or application workflows, set the Image Registry Operator managementState to Managed and configure a supported, persistent storage backend appropriate for the platform. Keep managementState: Removed only when the internal registry is deliberately disabled and all dependent workflows use an external registry; Unmanaged should be used only when the organization intentionally assumes responsibility for the registry configuration and lifecycle.

verification SHALL be:

1. Print Operator state and storage ownership:
   `oc get configs.imageregistry.operator.openshift.io cluster -o custom-columns=STATE:.spec.managementState,STORAGE_MGMT:.spec.storage.managementState,EMPTYDIR:.spec.storage.emptyDir,PVC:.spec.storage.pvc.claim`
2. Read `STATE` (Image Registry Operator):
      - `Removed`: no Operator-managed registry. Valid if this cluster uses only an external registry.
      - `Managed`: Operator reconciles the registry.
      - `Unmanaged`: Operator ignores config changes. A user-managed registry with user-provided storage is valid.
3. Read `STORAGE_MGMT` (`spec.storage.managementState`, not `STATE`):
      - `Managed`: Operator applies default storage settings.
      - `Unmanaged`: you brought the bucket or PVC. Valid with `STATE=Managed` or `STATE=Unmanaged`.
4. If this cluster needs an Operator-reconciled registry and `STATE` is `Removed`:
   `oc patch configs.imageregistry.operator.openshift.io cluster --type=merge -p '{"spec":{"managementState":"Managed"}}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

image registry pods and dependent build/image workflows

impact_detail SHALL be:

Changing registry state or storage rolls registry pods and can briefly interrupt internal image pushes, pulls, and build flows while the new backend comes online.

`finding_group` SHALL be `registry-management-state`.

`finding_group_title` SHALL be `Internal registry state`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/registry/index#registry-operator-configuration-resource-overview_configuring-registry-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/registry/index#registry-operator-configuration-resource-overview_configuring-registry-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/registry/index#registry-operator-configuration-resource-overview_configuring-registry-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/registry/index#registry-operator-configuration-resource-overview_configuring-registry-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/registry/index#registry-operator-configuration-resource-overview_configuring-registry-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/registry/index#registry-operator-configuration-resource-overview_configuring-registry-operator`.

#### Scenario: 7.3.registry.state loads
- WHEN `get_entry` is called with `7.3.registry.state`
- THEN the title is `Internal registry state`
- AND `content_from` is empty


### Requirement: KB 7.3.storage.csi
`load_kb()` SHALL contain `7.3.storage.csi` from `7_3_components.toml`. Title SHALL be `CSI driver availability`.

description SHALL be:

CSI drivers provide the standard interface for dynamic volume provisioning,
snapshots, and resize. Storage classes backed by legacy in-tree or
vendor-specific provisioners without a CSI driver miss newer storage features
and may not be supported on future OCP releases.

recommendation SHALL be:

Validate the storage platform design with the storage vendor before treating the absence of a CSIDriver object as a defect. Portworx uses pxd.portworx.com for CSI-backed StorageClasses, so a missing CSIDriver resource may indicate an incomplete or legacy installation rather than proof that the StorageClass is unsupported. If the platform is running a legacy or non-CSI storage integration, plan a vendor-supported migration to the current CSI deployment before future OpenShift upgrades. Do not create a new in-tree StorageClass or install a generic operator solely to make the check pass; install or upgrade the vendor-supported CSI operator only after confirming the supported migration and compatibility path.

verification SHALL be:

1. List installed CSI drivers and compare against the provisioners referenced by existing StorageClasses:
   `oc get csidrivers`
   `oc get storageclass -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner`
2. If a provisioner has no matching CSIDriver, install the vendor's CSI Operator (for example the Portworx or vendor-specific Operator from OperatorHub) so provisioning goes through the supported CSI path.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

storage platform and workloads using the affected StorageClasses

impact_detail SHALL be:

Consult the storage vendor for the impact of any CSI operator install or legacy-to-CSI migration. Red Hat does not define a single impact profile for third-party storage migrations; cutover can range from adding CSI pods with no node reboot to a planned backend migration that affects volume provisioning and attached workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`.

#### Scenario: 7.3.storage.csi loads
- WHEN `get_entry` is called with `7.3.storage.csi`
- THEN the title is `CSI driver availability`
- AND `content_from` is empty


### Requirement: KB 7.3.storage.default_sc
`load_kb()` SHALL contain `7.3.storage.default_sc` from `7_3_components.toml`. Title SHALL be `Default storage class`.

description SHALL be:

A default StorageClass is required for dynamic PVC provisioning. Without one,
PVCs without an explicit `storageClassName` remain Pending. Only one
StorageClass should be marked as default.

recommendation SHALL be:

Annotate exactly one StorageClass as default. Zero leaves omitted-class PVCs Pending; more than one makes the provisioner pick arbitrarily. Existing volumes do not move.

verification SHALL be:

1. Confirm the default StorageClass annotation (exactly one true). Zero is **WARNING**; more than one true is **WARNING**:
   `oc get storageclass -o json | jq -r '(["NAME","PROVISIONER","DEFAULT"], (.items[] | [.metadata.name, .provisioner, (.metadata.annotations["storageclass.kubernetes.io/is-default-class"] // "false")])) | @tsv' | column -t -s $'\t' | awk 'NR==1{print; next} {print; n++; if ($3=="true") d++} END{if (d==1) print "PASS 1 default-sc"; else if (d+0==0) print "WARNING no-default"; else print "WARNING", d+0, "multiple-default"}'`
2. If **WARNING** no-default, annotate the class that should back unbound PVCs:
   `oc patch storageclass <name> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'`
3. If **WARNING** multiple-default, leave one true and set the others to false:
   `oc patch storageclass <name> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

new PVC provisioning behavior

impact_detail SHALL be:

Changing the default StorageClass affects only future PVCs that omit storageClassName; existing volumes and nodes are untouched.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#change-default-storage-class_dynamic-provisioning`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#change-default-storage-class_dynamic-provisioning`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#change-default-storage-class_dynamic-provisioning`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#change-default-storage-class_dynamic-provisioning`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#change-default-storage-class_dynamic-provisioning`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#change-default-storage-class_dynamic-provisioning`.

#### Scenario: 7.3.storage.default_sc loads
- WHEN `get_entry` is called with `7.3.storage.default_sc`
- THEN the title is `Default storage class`
- AND `content_from` is empty


### Requirement: KB 7.3.storage.pvcs
`load_kb()` SHALL contain `7.3.storage.pvcs` from `7_3_components.toml`. Title SHALL be `Persistent volume claims`.

description SHALL be:

Unbound PVCs indicate that requested storage could not be provisioned, often
because the StorageClass is missing, capacity is unavailable, or the requested
access mode does not match the backend.

recommendation SHALL be:

Investigate and resolve each PVC that is not in the Bound phase before the dependent workload is deployed or restarted. Begin with the PVC's events to identify the immediate provisioning or binding failure, then validate the referenced StorageClass, CSI driver/provisioner health and logs, backend capacity, topology constraints, access-mode compatibility, requested size, and any required credentials or secrets. Workloads that omit storageClassName cannot dynamically provision storage until a valid default class is defined or a StorageClass is specified explicitly.

verification SHALL be:

1. List PVCs that are not Bound:
   `oc get pvc -A --no-headers -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase,SC:.spec.storageClassName | awk '$3 != "Bound"'`
      Empty output: all Bound. This check is done.
2. For each remaining row, read Events:
   `oc describe pvc <name> -n <ns>`
      Typical Events: StorageClass not found, no PVs, access mode mismatch, insufficient capacity.
3. Provisioner logs are in the CSI/driver namespace for that SC's provisioner.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

unbound PVCs and their provisioner path

impact_detail SHALL be:

Fixing StorageClass, CSI, or backend capacity lets the claim bind. Dependent pods stay down until Bound; nodes are not rebooted.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#storage-persistent-storage-pvc_understanding-persistent-storage`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#storage-persistent-storage-pvc_understanding-persistent-storage`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#storage-persistent-storage-pvc_understanding-persistent-storage`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#storage-persistent-storage-pvc_understanding-persistent-storage`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#storage-persistent-storage-pvc_understanding-persistent-storage`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#storage-persistent-storage-pvc_understanding-persistent-storage`.

#### Scenario: 7.3.storage.pvcs loads
- WHEN `get_entry` is called with `7.3.storage.pvcs`
- THEN the title is `Persistent volume claims`
- AND `content_from` is empty


### Requirement: KB 7.3.dns.operator
`load_kb()` SHALL contain `7.3.dns.operator` from `7_3_components.toml`. Title SHALL be `DNS Operator`.

description SHALL be:

The DNS Operator manages CoreDNS and is critical for service discovery. A
degraded DNS Operator can cause intermittent name-resolution failures across
the cluster.

recommendation SHALL be:

Bring `dns.operator default` to healthy conditions. If it is degraded, read conditions, then openshift-dns pods. Do not scale CoreDNS until you know whether the Operator or the daemonset is degraded.

verification SHALL be:

1. Confirm `dns.operator default` (`Available=True`, `Progressing=False`, `Degraded=False`):
   `oc get dns.operator default -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}' | awk -F= '$1=="Available"{a=$2} $1=="Progressing"{p=$2} $1=="Degraded"{d=$2} END{print (a=="True" && p=="False" && d=="False"?"PASS":"FAIL"), "Available="a, "Progressing="p, "Degraded="d}'`
2. If the operator is not healthy, print conditions:
   `oc get dns.operator default -o jsonpath='{range .status.conditions[*]}{.type}={.status} reason={.reason}{"\n"}{end}'`
3. Check DNS pods:
   `oc get pods -n openshift-dns`

impact SHALL be:

workload-shift

impact_scope SHALL be:

openshift-dns pods

impact_detail SHALL be:

Restoring dns.operator default rolls CoreDNS and can briefly break name resolution. It does not reboot nodes.

`finding_group` SHALL be `dns-operator-health`.

`finding_group_title` SHALL be `DNS Operator / CoreDNS health`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_operators/index#nw-dns-operator_dns-operator`.

#### Scenario: 7.3.dns.operator loads
- WHEN `get_entry` is called with `7.3.dns.operator`
- THEN the title is `DNS Operator`
- AND `content_from` is empty


### Requirement: KB 7.3.monitoring.config
`load_kb()` SHALL contain `7.3.monitoring.config` from `7_3_components.toml`. Title SHALL be `Monitoring configuration`.

description SHALL be:

The cluster monitoring stack (Prometheus and Alertmanager) is currently using temporary storage. This means all collected metrics, alert history, and dashboard data are lost whenever a monitoring pod restarts. For production clusters, persistent storage must be configured so metrics survive restarts.

recommendation SHALL be:

Add a volumeClaimTemplate PVC on an available StorageClass for Prometheus and Alertmanager, apply, and confirm Bound. Without it, metrics vanish on every restart.

verification SHALL be:

1. Print whether `prometheusK8s` has a `volumeClaimTemplate`:
   `oc -n openshift-monitoring get configmap cluster-monitoring-config -o jsonpath='{.data.config\.yaml}' | grep -E 'prometheusK8s:|volumeClaimTemplate:|retention:'`
2. If `volumeClaimTemplate` is missing, add one that references an available StorageClass and apply:
   `oc apply -f <cluster-monitoring-config.yaml> -n openshift-monitoring`
3. Verify Prometheus PVCs are Bound:
   `oc get pvc -n openshift-monitoring`

impact SHALL be:

workload-shift

impact_scope SHALL be:

Prometheus, Alertmanager, and related monitoring pods

impact_detail SHALL be:

Updating cluster-monitoring-config redeploys affected monitoring components and can create temporary gaps in metrics collection, alert evaluation, or dashboards.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.20` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.20/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`.

A summary pattern containing `volumeClaimTemplate` SHALL produce `cluster-monitoring-config has no volumeClaimTemplate; Prometheus storage is ephemeral.`.

#### Scenario: 7.3.monitoring.config loads
- WHEN `get_entry` is called with `7.3.monitoring.config`
- THEN the title is `Monitoring configuration`
- AND `content_from` is empty


### Requirement: KB 7.3.webhooks.validatingwebhooks
`load_kb()` SHALL contain `7.3.webhooks.validatingwebhooks` from `7_3_components.toml`. Title SHALL be `Validating admission webhooks`.

description SHALL be:

Validating admission webhooks admit or deny API requests without changing the
object. A `failurePolicy=Fail` hook or a slow/down backend can reject creates
and updates cluster-wide (pods, configs, CRDs). This scan is ValidatingWebhookConfiguration
timeout and failurePolicy.

recommendation SHALL be:

Review validating webhooks with failurePolicy: Fail or long timeouts, particularly those with broad rules or access to platform namespaces, because an unavailable backend can reject API requests and block cluster operations. Keep Fail only where denial during webhook failure is required, scope rules to the intended resources and namespaces, and set an explicit timeout of no more than 10 seconds.

verification SHALL be:

1. This is the validating (admit/deny) scan. Count `failurePolicy=Fail` hooks (more than zero needs review; shipped operators commonly use Fail with an empty selector):
   `oc get validatingwebhookconfigurations -o json | jq '[.items[].webhooks[]? | select(.failurePolicy=="Fail")] | length' | awk '{print ($1==0?"PASS":"WARNING"), "fail_policy="$1}'`
2. Print `CONFIG`, `HOOK`, `TIMEOUT`, `POLICY`, `SERVICE` for `timeoutSeconds>10` (any listed row needs review):
   `oc get validatingwebhookconfigurations -o json | jq -r '"CONFIG\tHOOK\tTIMEOUT\tPOLICY\tSERVICE", (.items[] as $config | $config.webhooks[]? | select((.timeoutSeconds // 10) > 10) | [$config.metadata.name, .name, (.timeoutSeconds // 10 | tostring), (.failurePolicy // "Ignore"), ((.clientConfig.service.namespace // "-")+"/"+(.clientConfig.service.name // "-"))] | @tsv)' | column -t | awk 'NR==1{print; next} {print; n++} END{print (n==0?"PASS":"WARNING"), n+0, "timeout>10"}'`
      Empty: no timeout issue.
3. Print Fail hooks whose selector values name `openshift-*`, `kube-system`, `kube-public`, or `default` (any listed row needs action):
   `oc get validatingwebhookconfigurations -o json | jq -r '"CONFIG\tHOOK\tNS_VALUES", (.items[] as $config | $config.webhooks[]? | select(.failurePolicy=="Fail") | [((.namespaceSelector.matchLabels // {})[]), (.namespaceSelector.matchExpressions[]?.values[]?)] as $ns | select(any($ns[]; type=="string" and (startswith("openshift-") or .=="kube-system" or .=="kube-public" or .=="default"))) | [$config.metadata.name, .name, ($ns|join(","))] | @tsv)' | column -t | awk 'NR==1{print; next} {print; n++} END{print (n==0?"PASS":"FAIL"), n+0, "fail_tier"}'`
      Empty: no Fail-policy issue from this check. If steps 1–3 are clean, the validating scan is done.
4. For each remaining SERVICE, print ready/notReady:
   `oc get endpointslice -n <ns> -l kubernetes.io/service-name=<svc> -o json | jq '{ready: ([.items[].endpoints[]? | select(.conditions.ready==true)] | length), notReady: ([.items[].endpoints[]? | select(.conditions.ready!=true)] | length)}'`
   `ready=0` means the webhook backend is down.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

validating webhook configurations

impact_detail SHALL be:

Narrowing rules, failurePolicy, or timeout is an API-object change and does not reboot nodes. An unavailable Fail webhook is already blocking APIs.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`.

#### Scenario: 7.3.webhooks.validatingwebhooks loads
- WHEN `get_entry` is called with `7.3.webhooks.validatingwebhooks`
- THEN the title is `Validating admission webhooks`
- AND `content_from` is empty


### Requirement: KB 7.3.webhooks.mutatingwebhooks
`load_kb()` SHALL contain `7.3.webhooks.mutatingwebhooks` from `7_3_components.toml`. Title SHALL be `Mutating admission webhooks`.

description SHALL be:

Mutating admission webhooks rewrite API objects before they are persisted
(defaults, sidecars, labels, security context). A `failurePolicy=Fail` hook or a
slow/down backend can block those mutations and stall admission. Unexpected
mutations also change cluster security posture. This scan is MutatingWebhookConfiguration
timeout and failurePolicy.

recommendation SHALL be:

Review mutating webhooks with failurePolicy: Fail or long timeouts, especially those that apply broadly, because an unavailable or slow backend can block API admission and prevent object creation or updates. Keep Fail only where mutation is essential, narrow the webhook scope to the intended resources and namespaces, and set an explicit timeout of no more than 10 seconds.

verification SHALL be:

1. This is the mutating (object-rewrite) scan. Count `failurePolicy=Fail` hooks (more than zero needs review; shipped operators commonly use Fail with an empty selector):
   `oc get mutatingwebhookconfigurations -o json | jq '[.items[].webhooks[]? | select(.failurePolicy=="Fail")] | length' | awk '{print ($1==0?"PASS":"WARNING"), "fail_policy="$1}'`
2. Print `CONFIG`, `HOOK`, `TIMEOUT`, `POLICY`, `SERVICE` for `timeoutSeconds>10` (any listed row needs review):
   `oc get mutatingwebhookconfigurations -o json | jq -r '"CONFIG\tHOOK\tTIMEOUT\tPOLICY\tSERVICE", (.items[] as $config | $config.webhooks[]? | select((.timeoutSeconds // 10) > 10) | [$config.metadata.name, .name, (.timeoutSeconds // 10 | tostring), (.failurePolicy // "Ignore"), ((.clientConfig.service.namespace // "-")+"/"+(.clientConfig.service.name // "-"))] | @tsv)' | column -t | awk 'NR==1{print; next} {print; n++} END{print (n==0?"PASS":"WARNING"), n+0, "timeout>10"}'`
      Empty: no timeout issue.
3. Print Fail hooks whose selector values name `openshift-*`, `kube-system`, `kube-public`, or `default` (any listed row needs action):
   `oc get mutatingwebhookconfigurations -o json | jq -r '"CONFIG\tHOOK\tNS_VALUES", (.items[] as $config | $config.webhooks[]? | select(.failurePolicy=="Fail") | [((.namespaceSelector.matchLabels // {})[]), (.namespaceSelector.matchExpressions[]?.values[]?)] as $ns | select(any($ns[]; type=="string" and (startswith("openshift-") or .=="kube-system" or .=="kube-public" or .=="default"))) | [$config.metadata.name, .name, ($ns|join(","))] | @tsv)' | column -t | awk 'NR==1{print; next} {print; n++} END{print (n==0?"PASS":"FAIL"), n+0, "fail_tier"}'`
      Empty: no Fail-policy issue from this check. If steps 1–3 are clean, the validating scan is done.
4. For each remaining SERVICE, print ready/notReady:
   `oc get endpointslice -n <ns> -l kubernetes.io/service-name=<svc> -o json | jq '{ready: ([.items[].endpoints[]? | select(.conditions.ready==true)] | length), notReady: ([.items[].endpoints[]? | select(.conditions.ready!=true)] | length)}'`
   `ready=0` means the webhook backend is down.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

mutating webhook configurations

impact_detail SHALL be:

Narrowing rules, failurePolicy, or timeout is an API-object change and does not reboot nodes. An unavailable Fail webhook is already blocking admission.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`.

#### Scenario: 7.3.webhooks.mutatingwebhooks loads
- WHEN `get_entry` is called with `7.3.webhooks.mutatingwebhooks`
- THEN the title is `Mutating admission webhooks`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_5_etcd_compaction
`load_kb()` SHALL contain `7.3.tsr.3_5_5_etcd_compaction` from `7_3_components.toml`. Title SHALL be `TSR etcd compaction`.

description SHALL be:

This check measures how long etcd takes to compact (clean up) its internal database on each control plane node. The reported percentile value (e.g. "95% quantile: 816ms") means that 95 out of 100 compaction operations completed within that time. The TSR NOTE (KCS 6271341) is about 200 ms on a small cluster and no more than 800–900 ms on a large cluster (20+ workers); that is not an OCP HTML SLA. Values above that usually mean slow disks, a large database, or heavy API traffic, and API responsiveness may be degraded.

recommendation SHALL be:

Keep 95th-percentile compaction under about 200 ms on a small cluster, or under 800–900 ms on a large cluster (20+ workers). If history is not compacting, compact to the current revision in a maintenance window. Compaction truncates MVCC history; it does not shrink DB SIZE on disk. Persistent latency after compact is control-plane disk contention, database growth, or high API traffic.

verification SHALL be:

1. Check the current etcd database size on every member:
   `oc -n openshift-etcd exec -c etcd etcd-<member> -- etcdctl endpoint status --cluster -w table`
      Look at the DB SIZE column — healthy clusters are typically under 8 GB.
2. Print the current revision from JSON status:
   `oc -n openshift-etcd exec -c etcd etcd-<member> -- etcdctl endpoint status --write-out json`
3. If history needs compaction, compact to that revision during a maintenance window:
   `oc -n openshift-etcd exec -c etcd etcd-<member> -- etcdctl --command-timeout=600s compact <revision>`
4. After compact, **PASS** when compaction latency improved. DB SIZE on disk does not drop until defragmentation. If compaction latency remains high, investigate disk I/O on the control plane nodes — slow storage is the most common root cause.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and etcd members

impact_detail SHALL be:

Manual etcd compact is a control-plane operation and should be done in a planned window with etcd backup protection.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#etcd-defrag_recommended-etcd-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-defrag_etcd-performance`, `kcs` -> `https://access.redhat.com/solutions/5564771`.

A summary pattern containing `95% quantile` SHALL produce `etcd compaction p95 exceeds ~200 ms (small cluster) or 800–900 ms (20+ workers).`.

#### Scenario: 7.3.tsr.3_5_5_etcd_compaction loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_5_etcd_compaction`
- THEN the title is `TSR etcd compaction`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_7_etcd_log_errors
`load_kb()` SHALL contain `7.3.tsr.3_5_7_etcd_log_errors` from `7_3_components.toml`. Title SHALL be `TSR etcd log errors`.

description SHALL be:

This check counts error messages in the etcd logs on each control plane node. The evidence shows how many errors were found and over what time window (e.g. "Found 8 messages within 16 minutes"). Any recurring errors — such as missed heartbeats, slow disk warnings, or peer communication failures — signal that etcd is struggling and the cluster's API layer may become unreliable if the root cause is not resolved.

recommendation SHALL be:

Heartbeat failures usually indicate overloaded CPU or slow WAL/backend disk writes, `request timed out` commonly indicates peer-network latency or packet loss, and `rafthttp: failed to read` requires validating etcd peer connectivity, certificates/TLS, DNS resolution, and time synchronization. Check WAL fsync and backend-commit latency, CPU throttling/pressure, and storage contention on each control-plane node; test RTT, loss, and MTU consistency between every etcd peer, with special attention to the member producing the most errors.

verification SHALL be:

1. Confirm each etcd member for the three phrases (`0` = none in the last hour):
   `for member in $(oc -n openshift-etcd get pods -l app=etcd -o jsonpath='{.items[*].metadata.name}'); do printf '%s ' "$member"; oc -n openshift-etcd logs "$member" -c etcd --since=1h | awk '/failed to send out heartbeat on time/{h++} /request timed out/{t++} /rafthttp: failed to read/{r++} END{print (h+t+r==0?"PASS":"FAIL"), "heartbeat="(h+0), "timed_out="(t+0), "rafthttp="(r+0)}'; done`
   `heartbeat`: slow disks or CPU starvation. `timed_out`: control-plane network. `rafthttp`: peer connectivity or TLS.
2. If the previous command failed, print the matching lines on that member:
   `oc -n openshift-etcd logs etcd-<member> -c etcd --since=1h | grep -E 'failed to send out heartbeat on time|request timed out|rafthttp: failed to read'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane storage, network, or CPU

impact_detail SHALL be:

Fixing etcd disk-performance problems usually requires control-plane infrastructure or storage changes that can reduce API capacity while nodes are remediated.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#understand-etcd-performance_etcd-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#recommended-etcd-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#understand-etcd-performance_etcd-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#understand-etcd-performance_etcd-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#understand-etcd-performance_etcd-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#understand-etcd-performance_etcd-overview`.

A summary pattern containing `there should be no messages` SHALL produce `etcd logs contain error messages that should not appear on a healthy control plane.`.

#### Scenario: 7.3.tsr.3_5_7_etcd_log_errors loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_7_etcd_log_errors`
- THEN the title is `TSR etcd log errors`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_8_1_etcd_disk_performance
`load_kb()` SHALL contain `7.3.tsr.3_5_8_1_etcd_disk_performance` from `7_3_components.toml`. Title SHALL be `TSR etcd disk performance`.

description SHALL be:

This check measures how quickly the control plane disks can write data durably. The reported value (e.g. "99% quantile: 31ms") means that 99 out of 100 operations completed within that time. Red Hat requires WAL fsync p99 below 10 ms. The TSR also requires backend commit p99 below 25 ms. When disks are too slow, etcd cannot keep up with cluster changes, causing API timeouts, leader elections, and potential cluster instability.

recommendation SHALL be:

Move etcd onto dedicated NVMe or enterprise SSD when WAL fsync p99 exceeds 10 ms or backend commit p99 exceeds 25 ms. BareMetal IPI needs high-IOPS storage for the control plane. Do not tune etcd to hide slow disks.

verification SHALL be:

1. Validate control plane storage with fio on each etcd node:
   `sudo podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/cloud-bulldozer/etcd-perf`
2. Check if control plane nodes are under CPU or memory pressure:
   `oc adm top nodes -l node-role.kubernetes.io/master=`
3. Review etcd latency metrics in Prometheus:
      - `histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m]))`
      - `histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m]))`
      - `histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket[2m]))`
4. If disk latency exceeds 10ms at the 99th percentile:
      - On bare metal: move /var/lib/etcd to a dedicated NVMe or SSD partition
      - On virtualized platforms: check for noisy-neighbor conditions, ensure storage is not shared with high-I/O workloads, and verify the backing datastore meets latency requirements
5. Keep the 99th percentile WAL fsync under 10ms and peer RTT under 50ms.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane nodes and etcd storage path

impact_detail SHALL be:

Fixing etcd disk-performance problems usually requires control-plane infrastructure or storage changes that can reduce API capacity while nodes are remediated.

`finding_group` SHALL be `etcd-disk-latency`.

`finding_group_title` SHALL be `TSR etcd disk performance`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#etcd-verify-hardware_recommended-etcd-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-verify-hardware_etcd-practices`.

A summary pattern containing `less than 10ms` SHALL produce `etcd WAL fsync p99 exceeds the 10 ms Red Hat threshold.`.

A summary pattern containing `less than 25ms` SHALL produce `etcd backend commit p99 exceeds the 25 ms TSR threshold.`.

#### Scenario: 7.3.tsr.3_5_8_1_etcd_disk_performance loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_8_1_etcd_disk_performance`
- THEN the title is `TSR etcd disk performance`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_6_2_registry_storage_type
`load_kb()` SHALL contain `7.3.tsr.3_6_2_registry_storage_type` from `7_3_components.toml`. Title SHALL be `TSR registry storage type`.

description SHALL be:

The internal image registry is using "emptyDir" (temporary) storage. This means all container images stored in the registry are lost when the registry pod restarts. Production clusters must use persistent storage (such as a PVC or object storage) so that pushed images are retained reliably.

recommendation SHALL be:

Set a persistent registry backend (PVC or object store). emptyDir is ephemeral: images vanish when the registry pod restarts. `managementState` is ownership, not the backend. Then confirm pods and that the pruner is not suspended.

verification SHALL be:

1. Confirm registry storage backend names only (not credentials). `managementState` is ownership, not a backend. `emptyDir` is ephemeral:
   `oc get configs.imageregistry.operator.openshift.io cluster -o json | jq -r '(.spec.storage | keys - ["managementState"]) as $backends | (if $backends == ["emptyDir"] then "FAIL" else "PASS" end) + " backends=" + ($backends | join(","))'`
2. If the previous command failed, set a persistent backend: PVC on bare metal, or the platform object store (S3, Azure Blob, GCS) on cloud.
3. Check registry pods:
   `oc get pods -n openshift-image-registry`
4. Confirm the image pruner is not suspended:
   `oc get imagepruner cluster -o custom-columns=NAME:.metadata.name,SUSPEND:.spec.suspend,SCHEDULE:.spec.schedule`

impact SHALL be:

workload-shift

impact_scope SHALL be:

image registry pods and backing storage

impact_detail SHALL be:

Changing registry storage backends rolls registry pods and can briefly interrupt image pushes, pulls, and build flows during cutover.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/registry/index#registry-configuring-storage-baremetal_configuring-registry-storage-baremetal`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/registry/index#registry-configuring-storage-baremetal_configuring-registry-storage-baremetal`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/registry/index#registry-configuring-storage-baremetal_configuring-registry-storage-baremetal`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/registry/index#registry-configuring-storage-baremetal_configuring-registry-storage-baremetal`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/registry/index#registry-configuring-storage-baremetal_configuring-registry-storage-baremetal`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/registry/index#registry-configuring-storage-baremetal_configuring-registry-storage-baremetal`.

A summary pattern containing `emptyDir` SHALL produce `The image registry is using emptyDir; images are lost on registry pod restart.`.

#### Scenario: 7.3.tsr.3_6_2_registry_storage_type loads
- WHEN `get_entry` is called with `7.3.tsr.3_6_2_registry_storage_type`
- THEN the title is `TSR registry storage type`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_7_2_monitoring_storage_type
`load_kb()` SHALL contain `7.3.tsr.3_7_2_monitoring_storage_type` from `7_3_components.toml`. Title SHALL be `TSR monitoring storage type`.

description SHALL be:

Platform monitoring stores Prometheus and Alertmanager data on a chosen backend. Typical problems are ephemeral emptyDir (metrics lost on restart) and RWX or file access modes (Red Hat recommends block storage).

recommendation SHALL be:

Put Prometheus and Alertmanager on persistent RWO block storage so metrics survive a pod restart. An empty `STORAGECLASS` of `<none>` means they are on emptyDir; that is not acceptable in production. `ReadWriteMany` file backends will attach, but Prometheus wants block. Configuring the volume claim template is a separate change from choosing the class.

verification SHALL be:

1. Confirm Prometheus and Alertmanager have a StorageClass and RWO access. An empty `STORAGECLASS` of `<none>` means emptyDir; `ReadWriteMany` means file storage:
   `oc get prometheus,alertmanager -n openshift-monitoring -o custom-columns=KIND:.kind,NAME:.metadata.name,STORAGECLASS:.spec.storage.volumeClaimTemplate.spec.storageClassName,ACCESS:.spec.storage.volumeClaimTemplate.spec.accessModes[*] | awk '{print} NR>1 && $3=="<none>"{e=1} NR>1 && $4 ~ /ReadWriteMany/{r=1} END{if(e) print "FAIL emptyDir"; else if(r) print "WARNING RWX"; else print "PASS"}'`
2. List monitoring PVCs and note `PHASE`, `SC`, and `MODE` (empty list means no PVCs):
   `oc get pvc -n openshift-monitoring -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,SC:.spec.storageClassName,MODE:.spec.accessModes[*]`
3. Print StorageClass provisioners (match the `SC` from step 2, or the candidates if emptyDir):
   `oc get sc -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner`
   `nfs`, `efs`, `azurefile`, or `cephfs` in `PROVISIONER` is file storage (WARNING). Prefer `ReadWriteOnce` on a block provisioner.
4.

impact SHALL be:

workload-shift

impact_scope SHALL be:

Prometheus and Alertmanager pods

impact_detail SHALL be:

Moving monitoring off emptyDir onto persistent RWO block storage redeploys those pods and can create temporary gaps in metrics collection, alert evaluation, or dashboards.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.20` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.20/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/configuring_core_platform_monitoring/index#configuring-a-persistent-volume-claim_storing-and-recording-data`.

A summary pattern containing `emptyDir` SHALL produce `Monitoring storage is emptyDir; metrics are lost on pod restart.`.

A summary pattern containing `RWX` SHALL produce `Monitoring uses RWX/file storage; block storage is recommended.`.

A summary pattern containing `file storage` SHALL produce `Monitoring uses RWX/file storage; block storage is recommended.`.

#### Scenario: 7.3.tsr.3_7_2_monitoring_storage_type loads
- WHEN `get_entry` is called with `7.3.tsr.3_7_2_monitoring_storage_type`
- THEN the title is `TSR monitoring storage type`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_13_webhooks
`load_kb()` SHALL contain `7.3.tsr.3_13_webhooks` from `7_3_components.toml`. Title SHALL be `TSR admission webhooks`.

description SHALL be:

Webhooks intercept every API request (e.g. creating pods, updating configs) and can approve, reject, or modify them. If a webhook's backing service is down or slow, it can block all API operations cluster-wide. This check flags webhooks that monitor critical resources or are configured to hard-fail (`failurePolicy=Fail`) when their service is unavailable.

recommendation SHALL be:

This section is a section index. Use the validating and mutating webhook children for scored recommendations. Do not delete webhooks from this parent.

impact SHALL be:

none

`include_in_findings` SHALL be false.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`.

A summary pattern containing `Failure Policy` SHALL produce `Webhooks watch critical API resources or use failurePolicy other than Ignore.`.

#### Scenario: 7.3.tsr.3_13_webhooks loads
- WHEN `get_entry` is called with `7.3.tsr.3_13_webhooks`
- THEN the title is `TSR admission webhooks`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_1_cluster_version
`load_kb()` SHALL contain `7.3.tsr.3_1_cluster_version` from `7_3_components.toml`. Title SHALL be `3.1. Cluster Version`.

description SHALL be:

Validates the current cluster version, available updates, and upgrade channel
configuration. Ensures the cluster is on a supported release and that the
upgrade path is clear for future maintenance.

recommendation SHALL be:

Put the cluster on a supported version and a current channel with a clear upgrade path. Fix a missing channel or blocked updates before you schedule. Version, channel, and `oc adm upgrade` are the upgrade-path snapshot.

verification SHALL be:

1. Print version, channel, and conditions from named `version`:
   `oc get clusterversion version -o jsonpath='{.status.desired.version}{" "}{.spec.channel}{"\n"}{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'`
   `oc adm upgrade`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster-wide

impact_detail SHALL be:

Addressing stale upgrade history usually means performing a cluster upgrade, which rolls operators, nodes, and workloads over time.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#understanding-openshift-updates`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#understanding-openshift-updates`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#understanding-openshift-updates`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#understanding-openshift-updates`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#understanding-openshift-updates`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#understanding-openshift-updates`.

#### Scenario: 7.3.tsr.3_1_cluster_version loads
- WHEN `get_entry` is called with `7.3.tsr.3_1_cluster_version`
- THEN the title is `3.1. Cluster Version`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_2_operators
`load_kb()` SHALL contain `7.3.tsr.3_2_operators` from `7_3_components.toml`. Title SHALL be `3.2. Operators`.

description SHALL be:

Overview section covering all installed operators including platform and
additional OLM-managed operators. Validates overall operator health, version
consistency, and subscription status across the cluster.

recommendation SHALL be:

This section is a section index. Use platform operators, additional operators, and `installPlanApproval` for scored recommendations.

verification SHALL be:

1. List unhealthy ClusterOperators only:
   `oc get co | grep -v 'True.*False.*False'`
2. List OLM subscription fields this section evaluates:
   `oc get subscription -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,CHANNEL:.spec.channel,STATE:.status.state,INSTALLED:.status.installedCSV,CURRENT:.status.currentCSV`
3. List CSV phase:
   `oc get csv -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/operators/index#olm-what-operators-are`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/operators/index#olm-what-operators-are`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/operators/index#olm-what-operators-are`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/operators/index#olm-what-operators-are`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/operators/index#olm-what-operators-are`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/operators/index#olm-what-operators-are`.

#### Scenario: 7.3.tsr.3_2_operators loads
- WHEN `get_entry` is called with `7.3.tsr.3_2_operators`
- THEN the title is `3.2. Operators`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_2_2_additional_operators
`load_kb()` SHALL contain `7.3.tsr.3_2_2_additional_operators` from `7_3_components.toml`. Title SHALL be `3.2.2. Additional Operators`.

description SHALL be:

Validates OLM-managed operators installed from OperatorHub beyond the platform
defaults. Checks subscription health, CSV phase, and whether installed operators
are actively used or orphaned.

recommendation SHALL be:

Review the affected Operator Subscription and determine why the automatic update has not completed. Confirm that the subscription is on the intended channel, inspect its conditions and referenced `InstallPlan` for catalog-source, dependency, resolution, or install failures, and then review the target CSV, related events, operator pods, and logs until the operator reaches a Succeeded CSV state. Do not delete the Subscription, CSV, or `InstallPlan` as a first response as debug information may be lost.

verification SHALL be:

1. List additional operator subscriptions and verify CSV status:
   `oc get subscription -A`
   `oc get csv -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase`
2. Investigate any CSV not in 'Succeeded' phase.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

the stuck Operator Subscription and CSV

impact_detail SHALL be:

Repairing catalog, InstallPlan, or CSV rolls that operator. It does not reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/operators/index#olm-adding-operators-to-a-cluster`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/operators/index#olm-adding-operators-to-a-cluster`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/operators/index#olm-adding-operators-to-a-cluster`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/operators/index#olm-adding-operators-to-a-cluster`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/operators/index#olm-adding-operators-to-a-cluster`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/operators/index#olm-adding-operators-to-a-cluster`.

#### Scenario: 7.3.tsr.3_2_2_additional_operators loads
- WHEN `get_entry` is called with `7.3.tsr.3_2_2_additional_operators`
- THEN the title is `3.2.2. Additional Operators`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_2_3_operators_plan_approval
`load_kb()` SHALL contain `7.3.tsr.3_2_3_operators_plan_approval` from `7_3_components.toml`. Title SHALL be `3.2.3. Operators Plan approval`.

`content_from` SHALL be `7.1.subs.approval` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.3.tsr.3_2_3_operators_plan_approval loads
- WHEN `get_entry` is called with `7.3.tsr.3_2_3_operators_plan_approval`
- THEN the title is `3.2.3. Operators Plan approval`
- AND `content_from` is `7.1.subs.approval`


### Requirement: KB 7.3.tsr.3_4_master_configuration
`load_kb()` SHALL contain `7.3.tsr.3_4_master_configuration` from `7_3_components.toml`. Title SHALL be `3.4. Master Configuration`.

description SHALL be:

Validates control plane node configuration including resource allocation,
schedulability settings, and infrastructure topology. Ensures control plane
nodes are properly sized and configured for the cluster workload.

recommendation SHALL be:

Keep control-plane nodes Ready, unschedulable for customer workloads unless this is compact, and not CPU/memory starved. Reverse `mastersSchedulable=true` on a non-compact cluster; resource pressure is sizing or noisy-neighbor.

verification SHALL be:

1. List control-plane nodes:
   `oc get nodes -l node-role.kubernetes.io/master=`
2. Print `mastersSchedulable` only:
   `oc get scheduler cluster -o jsonpath='{.spec.mastersSchedulable}{"\n"}'`
3. Inspect control plane resource pressure:
   `oc adm top nodes -l node-role.kubernetes.io/master=`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

control-plane scheduling

impact_detail SHALL be:

Adding the taint stops new user workloads from landing on control-plane nodes, but it does not reboot nodes or evict existing pods automatically.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#control-plane`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#control-plane`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#control-plane`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#control-plane`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#control-plane`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#control-plane`.

#### Scenario: 7.3.tsr.3_4_master_configuration loads
- WHEN `get_entry` is called with `7.3.tsr.3_4_master_configuration`
- THEN the title is `3.4. Master Configuration`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_etcd
`load_kb()` SHALL contain `7.3.tsr.3_5_etcd` from `7_3_components.toml`. Title SHALL be `3.5. ETCD`.

description SHALL be:

Parent section covering etcd cluster health including membership, leader
election, database size, compaction, defragmentation, performance, and alerts.
etcd is the backbone of the Kubernetes control plane.

recommendation SHALL be:

This section is a section index. Use the etcd endpoint, leader, health, size, compaction, defrag, performance, and alert children. Do not defrag or replace a member from this parent.

verification SHALL be:

1. Check etcd pods:
   `oc get pods -n openshift-etcd`
2. Print etcd operator conditions only:
   `oc get etcd cluster -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'`
3. For detailed member status use:
   `oc -n openshift-etcd exec -c etcd etcd-<node> -- etcdctl endpoint status --cluster -w table`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-overview`.

#### Scenario: 7.3.tsr.3_5_etcd loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_etcd`
- THEN the title is `3.5. ETCD`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_1_etcd_endpoints
`load_kb()` SHALL contain `7.3.tsr.3_5_1_etcd_endpoints` from `7_3_components.toml`. Title SHALL be `3.5.1. ETCD Endpoints`.

description SHALL be:

Validates that all etcd member endpoints are reachable and responding. Missing
or unreachable endpoints indicate member failure or network partitioning that
can lead to quorum loss.

recommendation SHALL be:

Make every member endpoint answer. Chase any unreachable member as a network or pod failure. Do not remove a member without a backup.

verification SHALL be:

1. Check etcd endpoint health:
   `oc -n openshift-etcd exec -c etcd etcd-<node> -- etcdctl endpoint health --cluster -w table`
2. Verify all members are listed and healthy.
3. Investigate any unreachable endpoints for network or pod issues.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and etcd members

impact_detail SHALL be:

Member recovery can require backup, replacement, or restore work on control-plane nodes and may reduce API availability while the cluster is stabilized.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-overview`.

#### Scenario: 7.3.tsr.3_5_1_etcd_endpoints loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_1_etcd_endpoints`
- THEN the title is `3.5.1. ETCD Endpoints`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_2_etcd_leader
`load_kb()` SHALL contain `7.3.tsr.3_5_2_etcd_leader` from `7_3_components.toml`. Title SHALL be `3.5.2. ETCD Leader`.

description SHALL be:

Verifies that the etcd cluster has a stable leader. Frequent leader changes
indicate network instability, disk latency, or resource pressure on control
plane nodes that can cause API server timeouts.

recommendation SHALL be:

Keep exactly one IS `LEADER=true`. Repeated elected-leader lines are disk, network, or CPU pressure, not a reason to restart etcd.

verification SHALL be:

1. Check the current leader and look at the IS LEADER column:
   `oc -n openshift-etcd exec -c etcd etcd-<node> -- etcdctl endpoint status --cluster -w table`
2. Monitor leader changes in etcd logs:
   `oc -n openshift-etcd logs etcd-<node> -c etcd | grep 'elected leader'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane storage, network, or CPU

impact_detail SHALL be:

Fixing etcd disk-performance problems usually requires control-plane infrastructure or storage changes that can reduce API capacity while nodes are remediated.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-overview`.

#### Scenario: 7.3.tsr.3_5_2_etcd_leader loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_2_etcd_leader`
- THEN the title is `3.5.2. ETCD Leader`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_3_etcd_health
`load_kb()` SHALL contain `7.3.tsr.3_5_3_etcd_health` from `7_3_components.toml`. Title SHALL be `3.5.3. ETCD Health`.

description SHALL be:

Assesses the overall health status of all etcd members including alarm state,
response time, and cluster consistency. Unhealthy members must be remediated
before they affect quorum.

recommendation SHALL be:

Clear etcd member health failures and alarms. A NOSPACE or CORRUPT alarm is stop-the-line — list it, then size or defrag, or restore from backup. All members healthy and no alarms is the expected end state.

verification SHALL be:

1. Verify member health:
   `oc -n openshift-etcd exec -c etcd etcd-<node> -- etcdctl endpoint health --cluster -w table`
2. Check for alarms:
   `oc -n openshift-etcd exec -c etcd etcd-<node> -- etcdctl alarm list`
3. Investigate and resolve any raised alarms.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and etcd members

impact_detail SHALL be:

Member recovery can require backup, replacement, or restore work on control-plane nodes and may reduce API availability while the cluster is stabilized.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-overview`.

#### Scenario: 7.3.tsr.3_5_3_etcd_health loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_3_etcd_health`
- THEN the title is `3.5.3. ETCD Health`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_4_etcd_database_size
`load_kb()` SHALL contain `7.3.tsr.3_5_4_etcd_database_size` from `7_3_components.toml`. Title SHALL be `3.5.4. ETCD Database Size`.

description SHALL be:

Monitors the etcd database size to ensure it remains within safe limits.
A database approaching the space quota (default 8GB) triggers alarms that
prevent further writes and can freeze the control plane.

recommendation SHALL be:

Keep DB SIZE off the 8 GB quota so NOSPACE cannot freeze writes. Schedule defrag only when size greatly exceeds in-use.

verification SHALL be:

1. Check database size and review the DB SIZE column:
   `oc -n openshift-etcd exec -c etcd etcd-<node> -- etcdctl endpoint status --cluster -w table`
2. If DB SIZE is approaching quota, review fragmentation in Prometheus and check etcd latency:
   `(etcd_mvcc_db_total_size_in_bytes - etcd_mvcc_db_total_size_in_use_in_bytes)/1024/1024`
   `histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m]))`
   `histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m]))`
3. If fragmentation remains high and DB SIZE greatly exceeds the in-use portion, schedule defragmentation.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and etcd members

impact_detail SHALL be:

Defragmentation briefly locks each etcd member and can cause transient API latency; schedule during a maintenance window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-defrag_etcd-performance`.

#### Scenario: 7.3.tsr.3_5_4_etcd_database_size loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_4_etcd_database_size`
- THEN the title is `3.5.4. ETCD Database Size`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_6_etcd_defragmentation
`load_kb()` SHALL contain `7.3.tsr.3_5_6_etcd_defragmentation` from `7_3_components.toml`. Title SHALL be `3.5.6. ETCD Defragmentation`.

description SHALL be:

Checks whether etcd defragmentation is needed or has been recently performed.
Fragmented backends consume more disk space than necessary and increase
fsync latency.

recommendation SHALL be:

Defrag in a maintenance window when fragmentation (DB SIZE minus in-use) is high. Take a backup first; the cluster command locks members.

verification SHALL be:

1. Compare DB SIZE vs IN USE columns from:
   `oc -n openshift-etcd exec -c etcd etcd-<node> -- etcdctl endpoint status --cluster -w table`
2. If fragmentation is high, schedule defragmentation during maintenance:
   `oc -n openshift-etcd exec -c etcd etcd-<node> -- etcdctl defrag --cluster`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and etcd members

impact_detail SHALL be:

Defragmentation briefly locks each etcd member and can cause transient API latency; schedule during a maintenance window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-defrag_etcd-performance`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-defrag_etcd-performance`.

#### Scenario: 7.3.tsr.3_5_6_etcd_defragmentation loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_6_etcd_defragmentation`
- THEN the title is `3.5.6. ETCD Defragmentation`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_8_etcd_performance
`load_kb()` SHALL contain `7.3.tsr.3_5_8_etcd_performance` from `7_3_components.toml`. Title SHALL be `3.5.8. ETCD Performance`.

description SHALL be:

Parent section covering etcd performance metrics including disk I/O, network
latency, and CPU utilization. Poor performance in any dimension causes raft
timeouts and API instability.

recommendation SHALL be:

This section is a section index. Use the disk, network, and CPU children for scored etcd performance recommendations.

verification SHALL be:

1. Validate control plane storage with `quay.io/cloud-bulldozer/etcd-perf`.
2. Review etcd latency metrics in Prometheus:
   `histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m]))`
   `histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m]))`
   `histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket[2m]))`
3. Use the disk and network subsections below to isolate the bottleneck.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-verify-hardware_etcd-practices`.

#### Scenario: 7.3.tsr.3_5_8_etcd_performance loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_8_etcd_performance`
- THEN the title is `3.5.8. ETCD Performance`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_8_2_etcd_network_performance
`load_kb()` SHALL contain `7.3.tsr.3_5_8_2_etcd_network_performance` from `7_3_components.toml`. Title SHALL be `3.5.8.2. ETCD Network Performance`.

description SHALL be:

Measures network round-trip latency between etcd members. OpenShift etcd
practices require the 99th percentile of `etcd_network_peer_round_trip_time`
to stay below 50 ms. Higher latency causes heartbeat timeouts, leader
elections, and request failures that propagate to the API server.

recommendation SHALL be:

Keep peer RTT under 50 ms. High latency causes heartbeat timeouts and elections. Fix control-plane network placement; do not chase an etcd flag.

verification SHALL be:

1. Test network latency between control plane nodes hosting etcd.
2. Review etcd logs for peer connectivity warnings:
   `oc -n openshift-etcd logs etcd-<node> -c etcd | grep -i 'overloaded network\|dial timeout\|peer'`
3. Ensure control plane nodes are on a low-latency network segment.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane peer network

impact_detail SHALL be:

Keeping peer RTT under 50 ms usually requires relocating control-plane nodes or changing the underlay and should be performed in a planned window. That work can interrupt API and etcd traffic until the new path is stable.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-verify-hardware_etcd-practices`.

#### Scenario: 7.3.tsr.3_5_8_2_etcd_network_performance loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_8_2_etcd_network_performance`
- THEN the title is `3.5.8.2. ETCD Network Performance`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_8_3_etcd_cpu_performance
`load_kb()` SHALL contain `7.3.tsr.3_5_8_3_etcd_cpu_performance` from `7_3_components.toml`. Title SHALL be `3.5.8.3. ETCD CPU Performance`.

description SHALL be:

Checks CPU pressure on control plane nodes running etcd. The TSR scores
etcd `cpu_iowait` and expects it below 4.0 seconds. CPU starvation causes
etcd request timeouts, slow commits, and can trigger leader elections that
affect the entire cluster.

recommendation SHALL be:

Move customer pods off masters or add CPU when `oc adm top` shows high steal on masters or etcd pods. etcd is latency-sensitive to CPU steal, especially if masters are schedulable.

verification SHALL be:

1. Review CPU usage on control plane nodes:
   `oc adm top nodes -l node-role.kubernetes.io/master=`
2. Check etcd container CPU usage:
   `oc adm top pods -n openshift-etcd`
3. Investigate noisy-neighbor workloads if control plane nodes are schedulable.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane nodes

impact_detail SHALL be:

Adding CPU or replacing control-plane nodes requires a maintenance window and can reduce API capacity while masters are remediated. Evicting user pods off schedulable masters reschedules those workloads without rebooting nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-verify-hardware_etcd-practices`.

#### Scenario: 7.3.tsr.3_5_8_3_etcd_cpu_performance loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_8_3_etcd_cpu_performance`
- THEN the title is `3.5.8.3. ETCD CPU Performance`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_5_9_etcd_alerts
`load_kb()` SHALL contain `7.3.tsr.3_5_9_etcd_alerts` from `7_3_components.toml`. Title SHALL be `3.5.9. ETCD Alerts`.

description SHALL be:

Reviews active Prometheus alerts related to etcd health, performance, and
quorum. Firing etcd alerts indicate conditions that require immediate
investigation to prevent control plane degradation.

recommendation SHALL be:

Clear firing etcd Prometheus alerts. Use the alertname to pick the child row. Do not silence etcd alerts to clear this check. Empty is healthy.

verification SHALL be:

1. See which etcd alerts are firing:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname | test("^etcd"; "i")) | {state, alertname: .labels.alertname, severity: .labels.severity}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and etcd members

impact_detail SHALL be:

Fixing etcd disk-performance problems usually requires control-plane infrastructure or storage changes that can reduce API capacity while nodes are remediated.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-overview`.

#### Scenario: 7.3.tsr.3_5_9_etcd_alerts loads
- WHEN `get_entry` is called with `7.3.tsr.3_5_9_etcd_alerts`
- THEN the title is `3.5.9. ETCD Alerts`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_6_registry
`load_kb()` SHALL contain `7.3.tsr.3_6_registry` from `7_3_components.toml`. Title SHALL be `3.6. Registry`.

description SHALL be:

Parent section covering internal image registry configuration, scaling, and
storage. The image registry is critical for builds, ImageStreams, and internal
image distribution.

recommendation SHALL be:

This section is a section index. Use replica count and storage type for scored recommendations.

verification SHALL be:

1. Print registry managementState, replicas, and storage backend names:
   `oc get configs.imageregistry.operator.openshift.io cluster -o custom-columns=STATE:.spec.managementState,REPLICAS:.spec.replicas,EMPTYDIR:.spec.storage.emptyDir,PVC:.spec.storage.pvc.claim`
2. Check registry pod health:
   `oc get pods -n openshift-image-registry`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/registry/index#configuring-registry-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/registry/index#configuring-registry-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/registry/index#configuring-registry-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/registry/index#configuring-registry-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/registry/index#configuring-registry-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/registry/index#configuring-registry-operator`.

#### Scenario: 7.3.tsr.3_6_registry loads
- WHEN `get_entry` is called with `7.3.tsr.3_6_registry`
- THEN the title is `3.6. Registry`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_6_1_registry_scaled
`load_kb()` SHALL contain `7.3.tsr.3_6_1_registry_scaled` from `7_3_components.toml`. Title SHALL be `3.6.1. Registry Scaled`.

description SHALL be:

Validates that the internal image registry is running multiple replicas for
high availability. A single-replica registry creates a single point of failure
for image pulls and pushes.

recommendation SHALL be:

Run two or more registry replicas only if the backend is RWX or object storage. A single replica is a single point of failure for ImageStreams and builds. Scale after you confirm storage type; RWO PVCs will not schedule a second replica.

verification SHALL be:

1. Check registry replica count:
   `oc get configs.imageregistry.operator.openshift.io cluster -o jsonpath='{.spec.replicas}'`
2. For HA, scale to at least 2 replicas and ensure the storage backend supports RWX access mode or use object storage.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

image registry pods

impact_detail SHALL be:

Scaling registry replicas adds pods without disrupting existing image operations.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/registry/index#configuring-registry-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/registry/index#configuring-registry-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/registry/index#configuring-registry-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/registry/index#configuring-registry-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/registry/index#configuring-registry-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/registry/index#configuring-registry-operator`.

#### Scenario: 7.3.tsr.3_6_1_registry_scaled loads
- WHEN `get_entry` is called with `7.3.tsr.3_6_1_registry_scaled`
- THEN the title is `3.6.1. Registry Scaled`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_7_monitoring
`load_kb()` SHALL contain `7.3.tsr.3_7_monitoring` from `7_3_components.toml`. Title SHALL be `3.7. Monitoring`.

description SHALL be:

Parent section covering cluster monitoring stack health, installation status,
and storage configuration. The monitoring stack provides metrics, alerting,
and observability for the entire cluster.

recommendation SHALL be:

This section is a section index. Use monitoring installed and storage type for scored recommendations. The volume claim template is a separate configuration change from choosing the class.

verification SHALL be:

1. Check monitoring pods:
   `oc get pods -n openshift-monitoring`
2. Print Prometheus replica, retention, and PVC storage class:
   `oc get prometheus -n openshift-monitoring -o custom-columns=NAME:.metadata.name,REPLICAS:.spec.replicas,RETENTION:.spec.retention,STORAGECLASS:.spec.storage.volumeClaimTemplate.spec.storageClassName`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/monitoring/index#monitoring-overview`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/monitoring/index#monitoring-overview`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/monitoring/index#monitoring-overview`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/monitoring/index#monitoring-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/monitoring/index#monitoring-overview`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/monitoring/index#monitoring-overview`.

#### Scenario: 7.3.tsr.3_7_monitoring loads
- WHEN `get_entry` is called with `7.3.tsr.3_7_monitoring`
- THEN the title is `3.7. Monitoring`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_7_1_monitoring_installed
`load_kb()` SHALL contain `7.3.tsr.3_7_1_monitoring_installed` from `7_3_components.toml`. Title SHALL be `3.7.1. Monitoring Installed`.

description SHALL be:

Verifies that the cluster monitoring stack is installed and all required
components (Prometheus, Alertmanager, Thanos, Grafana) are running. Missing
components impair observability and alerting.

recommendation SHALL be:

Bring Prometheus, Alertmanager, and the monitoring ClusterOperator to Available with pods Running. Start at the ClusterOperator, then the namespace pods. Do not reinstall the stack until the Operator says what is degraded.

verification SHALL be:

1. Verify all monitoring pods are running and check the cluster-monitoring-operator status:
   `oc get pods -n openshift-monitoring`
   `oc get co monitoring`
2. Investigate any pods not in Running/Completed state.

impact SHALL be:

workload-shift

impact_scope SHALL be:

openshift-monitoring pods

impact_detail SHALL be:

Updating cluster-monitoring-config redeploys affected monitoring components and can create temporary gaps in metrics collection, alert evaluation, or dashboards.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/configuring_core_platform_monitoring/index`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/configuring_core_platform_monitoring/index`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/configuring_core_platform_monitoring/index`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/monitoring/index#monitoring-overview`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/configuring_core_platform_monitoring/index`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/configuring_core_platform_monitoring/index`.

#### Scenario: 7.3.tsr.3_7_1_monitoring_installed loads
- WHEN `get_entry` is called with `7.3.tsr.3_7_1_monitoring_installed`
- THEN the title is `3.7.1. Monitoring Installed`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_8_ingress_controller
`load_kb()` SHALL contain `7.3.tsr.3_8_ingress_controller` from `7_3_components.toml`. Title SHALL be `3.8. Ingress Controller`.

description SHALL be:

Parent section covering ingress controller configuration including HAProxy
status, tuning parameters, and sharding. Ingress controllers handle all
external traffic routing into the cluster.

recommendation SHALL be:

This section is a section index. Use HAProxy status, tuning, and sharding for scored recommendations. Scale router replicas to traffic and keep them Running on more than one node.

verification SHALL be:

1. Print ingress controller replica counts and domain:
   `oc get ingresscontroller -n openshift-ingress-operator -o custom-columns=NAME:.metadata.name,SPEC:.spec.replicas,AVAILABLE:.status.availableReplicas,DOMAIN:.status.domain`
2. Check router pods:
   `oc get pods -n openshift-ingress`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`.

#### Scenario: 7.3.tsr.3_8_ingress_controller loads
- WHEN `get_entry` is called with `7.3.tsr.3_8_ingress_controller`
- THEN the title is `3.8. Ingress Controller`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_8_1_haproxy_status
`load_kb()` SHALL contain `7.3.tsr.3_8_1_haproxy_status` from `7_3_components.toml`. Title SHALL be `3.8.1. HAProxy Status`.

description SHALL be:

Validates that the default HAProxy-based ingress router pods are running and
healthy across scheduled nodes. Degraded routers cause external traffic
blackouts for affected routes.

recommendation SHALL be:

Configure the default IngressController with node placement that matches the intended router nodes. If the selected nodes are control-plane nodes with a NoSchedule master taint, add the matching toleration or, preferably, place router pods on dedicated worker or infrastructure nodes. Verify that router pods become schedulable and that the default IngressController reaches `Available=True`, `Progressing=False`, and `Degraded=False`.

verification SHALL be:

1. Confirm `ingresscontroller default` (`Available=True`, `Progressing=False`, `Degraded=False`):
   `oc get ingresscontroller default -n openshift-ingress-operator -o json | jq -r '.status.conditions as $c | (first($c[] | select(.type=="Available") | .status) // "-") as $a | (first($c[] | select(.type=="Progressing") | .status) // "-") as $p | (first($c[] | select(.type=="Degraded") | .status) // "-") as $d | (first($c[] | select(.type=="CanaryChecksSucceeding") | .status) // "-") as $canary | (if $a=="True" and $p=="False" and $d=="False" then "PASS" else "FAIL" end) + " Available="+$a+" Progressing="+$p+" Degraded="+$d+" Canary="+$canary'`
2. Print router pod `READY` and `STATUS`:
   `oc get pods -n openshift-ingress -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount,NODE:.spec.nodeName | awk '{print} NR>1 && ($2!="true" || $3!="Running"){bad=1} END{print (bad?"FAIL":"PASS"), "router pods"}'`
3. Grep klog errors and reload/TLS failures for the last hour (empty = none). Healthy lines are `parseIPList` and `router reloaded`:
   `oc logs -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default --since=1h | grep -E '^E|^F|reload failed|error reloading|x509'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

default IngressController router pods

impact_detail SHALL be:

Changing node placement or tolerations reschedules router pods and can briefly interrupt ingress. It does not reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#configuring-ingress-cluster-traffic-ingress-controller`.

#### Scenario: 7.3.tsr.3_8_1_haproxy_status loads
- WHEN `get_entry` is called with `7.3.tsr.3_8_1_haproxy_status`
- THEN the title is `3.8.1. HAProxy Status`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_8_2_ingress_controller_tuning
`load_kb()` SHALL contain `7.3.tsr.3_8_2_ingress_controller_tuning` from `7_3_components.toml`. Title SHALL be `3.8.2. Ingress Controller Tuning`.

description SHALL be:

Reviews ingress controller tuning parameters such as thread count, connection
timeouts, and resource limits. Suboptimal tuning can cause connection drops
under load or excessive resource consumption.

recommendation SHALL be:

Leave Operator default tuningOptions unless you have a measured reason to change them. Treat health-check intervals below 5s as excess probe load. Scale to traffic; do not print the CR as the recommendation.

verification SHALL be:

1. Print named `tuningOptions` fields (`<none>` or `0s` = Operator default):
   `oc get ingresscontroller default -n openshift-ingress-operator -o custom-columns=NAME:.metadata.name,THREADS:.spec.tuningOptions.threadCount,MAXCONN:.spec.tuningOptions.maxConnections,CLIENT:.spec.tuningOptions.clientTimeout,SERVER:.spec.tuningOptions.serverTimeout,TUNNEL:.spec.tuningOptions.tunnelTimeout,HEALTH:.spec.tuningOptions.healthCheckInterval,RELOAD:.spec.tuningOptions.reloadInterval | column -t`
2. Treat empty/`0s` as defaults (engine is **INFO** either way):
   `oc get ingresscontroller default -n openshift-ingress-operator -o json | jq -r '(.spec.tuningOptions // {}) as $t | [$t | to_entries[] | select(.value != null and .value != "" and .value != 0 and .value != "0s")] as $custom | if ($custom|length)==0 then "PASS defaults" else "INFO custom "+($custom | map(.key+"="+(.value|tostring)) | join(" ")) end'`
3. Documented defaults when `<none>` or `0s` (IngressController CRD): `threadCount` 4 (max 64), `maxConnections` 50000, `clientTimeout`/`serverTimeout` 30s, `clientFinTimeout`/`serverFinTimeout` 1s, `tunnelTimeout` 1h, `healthCheckInterval` 5s, `reloadInterval` 5s, `tlsInspectDelay` 5s. `healthCheckInterval` below 5s causes excess backend probes. Leave defaults unless you have a measured need.
4. Print router container requests/limits:
   `oc get deploy -n openshift-ingress -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.template.spec.containers[0].resources.requests.cpu,MEM_REQ:.spec.template.spec.containers[0].resources.requests.memory,CPU_LIM:.spec.template.spec.containers[0].resources.limits.cpu,MEM_LIM:.spec.template.spec.containers[0].resources.limits.memory | column -t`
      Empty `CPU_LIM`/`MEM_LIM` is the Operator default.
5. Compare IngressController tuning parameters to the documented defaults using the link in the reference.

impact SHALL be:

workload-shift

impact_scope SHALL be:

IngressController pods

impact_detail SHALL be:

Changing tuningOptions rolls router pods and can briefly interrupt ingress. Leave Operator defaults unless you have a measured reason.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#nw-ingress-controller-configuration-parameters_configuring-ingress`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#nw-ingress-controller-configuration-parameters_configuring-ingress`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#nw-ingress-controller-configuration-parameters_configuring-ingress`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#nw-ingress-controller-configuration-parameters_configuring-ingress`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#nw-ingress-controller-configuration-parameters_configuring-ingress`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#nw-ingress-controller-configuration-parameters_configuring-ingress`.

#### Scenario: 7.3.tsr.3_8_2_ingress_controller_tuning loads
- WHEN `get_entry` is called with `7.3.tsr.3_8_2_ingress_controller_tuning`
- THEN the title is `3.8.2. Ingress Controller Tuning`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_8_3_ingress_sharding
`load_kb()` SHALL contain `7.3.tsr.3_8_3_ingress_sharding` from `7_3_components.toml`. Title SHALL be `3.8.3. Ingress Sharding`.

description SHALL be:

Checks whether ingress sharding is configured to distribute routes across
multiple ingress controllers. Sharding enables traffic isolation, separate
scaling, and domain-based routing policies.

recommendation SHALL be:

If you run more than one IngressController, keep selectors from overlapping unless that overlap is intentional. A single controller with empty selectors means sharding is not in use and is normal.

verification SHALL be:

1. List controllers (1 row = sharding not applicable):
   `oc get ingresscontroller -n openshift-ingress-operator`
2. Print routeSelector and namespaceSelector per controller ({} / empty admits all routes). hypershift.openshift.io/hosted-control-plane:DoesNotExist on default is the platform filter, not a user shard:
   `oc get ingresscontroller -n openshift-ingress-operator -o json | jq -r '.items[] | [.metadata.name, ((.spec.routeSelector // {})|tostring), ((.spec.namespaceSelector // {})|tostring)] | @tsv'`
3. Count routes by admitted router. OVERLAP is routes admitted by more than one controller (unrestricted default still admits shard routes):
   `oc get route -A -o json | jq -r '.items as $routes | (["ROUTER","ADMITTED"], ([$routes[] | (([.status.ingress[]?.routerName] | unique) | if length==0 then ["none"] else . end)[]] | group_by(.)[] | [.[0], (length|tostring)]), ["OVERLAP", ([$routes[] | select(([.status.ingress[]?.routerName] | unique | length)>1)] | length | tostring)]) | @tsv' | column -t`

impact SHALL be:

workload-shift

impact_scope SHALL be:

IngressControllers whose selectors overlap

impact_detail SHALL be:

Fixing overlapping selectors reschedules routes and router pods and can briefly interrupt ingress for the moved routes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#nw-ingress-sharding_configuring-ingress`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#nw-ingress-sharding_configuring-ingress`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#nw-ingress-sharding_configuring-ingress`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#nw-ingress-sharding_configuring-ingress`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#nw-ingress-sharding_configuring-ingress`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#nw-ingress-sharding_configuring-ingress`.

#### Scenario: 7.3.tsr.3_8_3_ingress_sharding loads
- WHEN `get_entry` is called with `7.3.tsr.3_8_3_ingress_sharding`
- THEN the title is `3.8.3. Ingress Sharding`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_9_storage
`load_kb()` SHALL contain `7.3.tsr.3_9_storage` from `7_3_components.toml`. Title SHALL be `3.9. Storage`.

description SHALL be:

Parent section covering storage provisioners, persistent volumes, CSI drivers,
and volume status. Storage is foundational for stateful workloads, monitoring,
and the image registry.

recommendation SHALL be:

This section is a section index. Keep a default class, CSI drivers that match provisioners, and Bound PVCs. Use the storage children for scored recommendations.

verification SHALL be:

1. Review storage classes and persistent volume status:
   `oc get storageclass`
   `oc get pv`
   `oc get pvc -A`
2. Check for unbound PVCs and verify CSI driver health:
   `oc get csidrivers`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#understanding-persistent-storage`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#understanding-persistent-storage`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#understanding-persistent-storage`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#understanding-persistent-storage`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#understanding-persistent-storage`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#understanding-persistent-storage`.

#### Scenario: 7.3.tsr.3_9_storage loads
- WHEN `get_entry` is called with `7.3.tsr.3_9_storage`
- THEN the title is `3.9. Storage`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_9_1_storage_provisioner_plugins
`load_kb()` SHALL contain `7.3.tsr.3_9_1_storage_provisioner_plugins` from `7_3_components.toml`. Title SHALL be `3.9.1. Storage Provisioner Plugins`.

description SHALL be:

Validates installed storage provisioners and their associated StorageClasses.
Missing or misconfigured provisioners prevent dynamic volume creation and
can block workload deployments.

recommendation SHALL be:

Keep at least one StorageClass and exactly one default. New PVCs that omit a class stay Pending without that.

verification SHALL be:

1. Print StorageClass PROVISIONER, reclaim policy, binding mode, expansion, and age ((default) marks the default class):
   `oc get storageclass | awk 'NR==1{print; next} {print; n++} END{print (n==0?"FAIL":"PASS"), n+0, "storageclasses"}'`
      Empty: no provisioners.
2. Confirm the default class name. Zero defaults is **WARNING** (PVCs that omit storageClassName stay Pending).
   `oc get storageclass -o json | jq -r '[.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true") | .metadata.name] | if length==0 then "WARNING no-default" elif length>1 then "WARNING multiple-default="+join(",") else "PASS default="+.[0] end'`
3. Count PVCs per StorageClass:
   `oc get pvc -A -o json | jq -r '(["SC","PVCS"], ([.items[] | .spec.storageClassName // "<none>"] | group_by(.)[] | [.[0], (length|tostring)])) | @tsv' | column -t`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

default StorageClass for new PVCs

impact_detail SHALL be:

Changing the default StorageClass affects only future PVCs that omit storageClassName; existing volumes and nodes are untouched.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#dynamic-provisioning`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#dynamic-provisioning`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#dynamic-provisioning`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#dynamic-provisioning`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#dynamic-provisioning`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#dynamic-provisioning`.

#### Scenario: 7.3.tsr.3_9_1_storage_provisioner_plugins loads
- WHEN `get_entry` is called with `7.3.tsr.3_9_1_storage_provisioner_plugins`
- THEN the title is `3.9.1. Storage Provisioner Plugins`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_9_2_storage_local_persistent_volumes
`load_kb()` SHALL contain `7.3.tsr.3_9_2_storage_local_persistent_volumes` from `7_3_components.toml`. Title SHALL be `3.9.2. Storage Local Persistent Volumes`.

description SHALL be:

Checks for local persistent volumes and their binding status. Local PVs tie
workloads to specific nodes, which complicates scheduling, failover, and
maintenance operations.

recommendation SHALL be:

Plan drains and disk failure around local-path PVs, or do not use them. A local-path PV pins the workload to that node. Empty list is healthy.

verification SHALL be:

1. List PVs that have a local path:
   `oc get pv -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,LOCAL:.spec.local.path --no-headers | awk '$3!="<none>" {print}'`
2. Verify bound PVCs and assess node-affinity constraints for maintenance planning.

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads pinned to local-path PVs

impact_detail SHALL be:

A local-path volume pins the pod to that node. Disk failure or a drain moves or stops that workload; nodes are not rebooted unless you also replace the disk.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#persistent-storage-using-local-volume`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#persistent-storage-using-local-volume`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#persistent-storage-using-local-volume`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#persistent-storage-using-local-volume`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#persistent-storage-using-local-volume`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#persistent-storage-using-local-volume`.

#### Scenario: 7.3.tsr.3_9_2_storage_local_persistent_volumes loads
- WHEN `get_entry` is called with `7.3.tsr.3_9_2_storage_local_persistent_volumes`
- THEN the title is `3.9.2. Storage Local Persistent Volumes`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_9_3_dynamic_storage_provisioner_plugins
`load_kb()` SHALL contain `7.3.tsr.3_9_3_dynamic_storage_provisioner_plugins` from `7_3_components.toml`. Title SHALL be `3.9.3. Dynamic Storage Provisioner Plugins`.

description SHALL be:

This check evaluates dynamic provisioner plugins. Failures include a provisioner that cannot bind volumes and a CSI (or in-tree) provisioner that Red Hat does not support for this platform.

recommendation SHALL be:

Classify the StorageClass before troubleshooting unbound PVCs: migrate in-tree provisioners to a supported CSI driver, investigate kubernetes.io/no-provisioner classes as static/local-storage designs, and remediate CSI provisioners that lack a matching healthy CSIDriver. For supported CSI classes, use PVC events and provisioner logs to resolve binding failures such as invalid parameters, insufficient backend capacity, topology, access-mode, or credential issues.

verification SHALL be:

1. Print platform type:
   `oc get infrastructure cluster -o custom-columns=TYPE:.status.platformStatus.type`
2. List installed CSIDriver names:
   `oc get csidriver -o custom-columns=DRIVER:.metadata.name | awk 'NR==1{print; next} {print; n++} END{print (n==0?"INFO":"PASS"), n+0, "csidrivers"}'`
3. Print each StorageClass provisioner (empty needs action no-storageclasses):
   `oc get sc -o custom-columns=SC:.metadata.name,PROVISIONER:.provisioner | awk 'NR==1{print; next} {print; n++} END{print (n==0?"FAIL":"INFO"), n+0, "storageclasses"}'`
4. Classify each StorageClass provisioner as static (kubernetes.io/no-provisioner), in-tree (other kubernetes.io/* names), csi (provisioner matches an installed CSIDriver), or missing-driver (needs action):
   `oc get sc -o json | jq -r --argjson drivers "$(oc get csidriver -o json | jq -c '[.items[].metadata.name]')" '["SC","PROVISIONER","KIND"], (.items[] | .provisioner as $p | [.metadata.name, $p, (if $p=="kubernetes.io/no-provisioner" then "static" elif ($p|startswith("kubernetes.io/")) then "in-tree" elif ($drivers|index($p)) then "csi" else "missing-driver" end)]) | @tsv' | column -t | awk 'NR==1{print; next} {print; n++; if($3=="missing-driver") miss=1; else if($3=="in-tree") tree=1; else if($3=="static") stat++} END{if(n==0) print "FAIL no-storageclasses"; else if(miss) print "FAIL missing-driver"; else if(tree) print "WARNING in-tree"; else if(stat==n) print "INFO no-dynamic-provisioners"; else print "PASS plugins-present"}'`
5. Print not-Bound PVCs (empty = none):
   `oc get pvc -A -o json | jq -r '(["NS","PVC","PHASE","SC"], (.items[] | select(.status.phase != "Bound") | [.metadata.namespace, .metadata.name, .status.phase, (.spec.storageClassName // "<none>")])) | @tsv' | column -t -s $'\t' | awk 'NR==1{print; next} {print; n++} END{print (n==0?"PASS":"FAIL"), n+0, "unbound"}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

storage platform and workloads using the affected StorageClasses

impact_detail SHALL be:

Consult the storage vendor for the impact of any CSI operator install or legacy-to-CSI migration. Red Hat does not define a single impact profile for third-party storage migrations; cutover can range from adding CSI pods with no node reboot to a planned backend migration that affects volume provisioning and attached workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#dynamic-provisioning`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#dynamic-provisioning`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#dynamic-provisioning`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#dynamic-provisioning`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#dynamic-provisioning`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#dynamic-provisioning`.

#### Scenario: 7.3.tsr.3_9_3_dynamic_storage_provisioner_plugins loads
- WHEN `get_entry` is called with `7.3.tsr.3_9_3_dynamic_storage_provisioner_plugins`
- THEN the title is `3.9.3. Dynamic Storage Provisioner Plugins`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_9_4_storage_pv_status
`load_kb()` SHALL contain `7.3.tsr.3_9_4_storage_pv_status` from `7_3_components.toml`. Title SHALL be `3.9.4. Storage PV Status`.

description SHALL be:

This check reviews PersistentVolume and PersistentVolumeClaim bind state. Evidence may show an unbound PV, an unbound PVC, or Released/Failed PVs that still consume capacity.

recommendation SHALL be:

Bind every PVC and clear Released or Failed PVs. Leftover PVs should be only Available or Bound. Empty exception output is the healthy end state.

verification SHALL be:

1. Print PVs whose STATUS is not Bound or Available (Released still holds capacity; Failed is **FAIL**). An empty list means none:
   `oc get pv -o custom-columns=NAME:.metadata.name,STATUS:.status.phase --no-headers | awk '$2!="Bound" && $2!="Available" {print}'`
2. Print PVCs whose PHASE is not Bound. An empty list means none:
   `oc get pvc -A --no-headers -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase,SC:.spec.storageClassName | awk '$3 != "Bound"'`

3. Compare PV and PVC phases to documented persistent-storage behavior using the link in the reference.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

Released or Failed PVs

impact_detail SHALL be:

Reclaiming leftover PVs does not reboot nodes. Bound workloads and existing volumes are untouched.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#understanding-persistent-storage`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#understanding-persistent-storage`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#understanding-persistent-storage`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#understanding-persistent-storage`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#understanding-persistent-storage`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#understanding-persistent-storage`.

#### Scenario: 7.3.tsr.3_9_4_storage_pv_status loads
- WHEN `get_entry` is called with `7.3.tsr.3_9_4_storage_pv_status`
- THEN the title is `3.9.4. Storage PV Status`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_9_5_csi_drivers
`load_kb()` SHALL contain `7.3.tsr.3_9_5_csi_drivers` from `7_3_components.toml`. Title SHALL be `3.9.5. CSI Drivers`.

description SHALL be:

This check lists Container Storage Interface drivers installed on the cluster and whether the Cluster CSI Driver operator manages them. A driver outside that Red Hat operator set is a third-party storage dependency, not proof the driver is broken.

recommendation SHALL be:

Treat any CSI driver that is not Red Hat-managed as a third-party storage dependency. Confirm that the storage vendor provides active support for the deployed CSI driver and that the driver version, Operator, storage platform or array firmware, and OpenShift release are listed as compatible in the vendor's current support matrix. A driver outside the Red Hat-supported CSI set is a support-boundary finding, not necessarily a health failure. Do not replace or remove it solely because it is vendor-managed; remediate when it is unhealthy, unsupported for the installed or target OpenShift version, lacks an active support path, or is no longer required by any `StorageClass`, `PersistentVolume`, `VolumeSnapshotClass`, or workload.

verification SHALL be:

1. Classify each CSIDriver against the ClusterCSIDriver CRD allow-list (CSO-managed OpenShift CSI operators). `RH_CSO=no` is not Red Hat-provided via that operator. ODF/LVMS are Red Hat products outside this list — use the doc URL for those names:
   `oc get csidriver -o json | jq -r --argjson enum "$(oc get crd clustercsidrivers.operator.openshift.io -o json | jq '[.spec.versions[] | select(.storage==true) | .. | objects | select(has("enum") and any(.enum[]; .=="ebs.csi.aws.com")) | .enum[]] | unique')" 'def in_enum($n): ($enum | index($n)) != null; (["DRIVER","RH_CSO"], (.items[] | [.metadata.name, (if in_enum(.metadata.name) then "yes" else "no" end)])) | @tsv' | column -t -s $'\t'`
2. Print VolumeSnapshotClass drivers (snapshot CSI names can appear here with no StorageClass). An empty list means none:
   `oc get volumesnapshotclass -o json | jq -r '(["NAME","DRIVER"], (.items[]? | [.metadata.name, (.driver // "-")])) | @tsv' | column -t -s $'\t' | awk 'NR==1{print; next} {print; n++} END{print (n==0?"INFO":"PASS"), n+0, "volumesnapshotclasses"}'`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#persistent-storage-csi-drivers-supported_persistent-storage-csi`.

#### Scenario: 7.3.tsr.3_9_5_csi_drivers loads
- WHEN `get_entry` is called with `7.3.tsr.3_9_5_csi_drivers`
- THEN the title is `3.9.5. CSI Drivers`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_9_6_storage_flexvolumes
`load_kb()` SHALL contain `7.3.tsr.3_9_6_storage_flexvolumes` from `7_3_components.toml`. Title SHALL be `3.9.6. Storage Flexvolumes`.

description SHALL be:

Detects usage of deprecated FlexVolume plugins. FlexVolumes are replaced by
CSI and may not be supported in future OCP versions. Migrate to CSI-based
storage before upgrading.

recommendation SHALL be:

Migrate every FlexVolume PV to the equivalent CSI driver before the next major version. An empty list is healthy. FlexVolume will not survive a future major upgrade.

verification SHALL be:

1. List FlexVolume PVs. Plan migration to the equivalent CSI driver before the next major version upgrade:
   `oc get pv -o custom-columns=NAME:.metadata.name,FLEX:.spec.flexVolume.driver --no-headers | awk '$2!="<none>" {print}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

workloads still on FlexVolume PVs

impact_detail SHALL be:

Consult the storage vendor for the impact of any CSI operator install or legacy-to-CSI migration. Red Hat does not define a single impact profile for third-party storage migrations; cutover can range from adding CSI pods with no node reboot to a planned backend migration that affects volume provisioning and attached workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#persistent-storage-csi`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#persistent-storage-csi`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#persistent-storage-csi`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#persistent-storage-csi`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#persistent-storage-csi`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#persistent-storage-csi`.

#### Scenario: 7.3.tsr.3_9_6_storage_flexvolumes loads
- WHEN `get_entry` is called with `7.3.tsr.3_9_6_storage_flexvolumes`
- THEN the title is `3.9.6. Storage Flexvolumes`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_10_kubernetes
`load_kb()` SHALL contain `7.3.tsr.3_10_kubernetes` from `7_3_components.toml`. Title SHALL be `3.10. Kubernetes`.

description SHALL be:

Parent section covering core Kubernetes networking and configuration components
including kube-proxy, OVN-Kubernetes, feature gates, and kubelet configuration.

recommendation SHALL be:

This section is a section index. Keep OVN-Kubernetes with Default featureSet and the kubelet pod capacity you intended. Use kube-proxy, OVNKube, feature gates, and `KubeletConfig` children for scored recommendations.

verification SHALL be:

1. Print cluster network type:
   `oc get network.config cluster -o jsonpath='{.spec.networkType}'`
2. Print applied pod capacity per node (`CAPACITY` is kubelet maxPods). An empty `KubeletConfig` list is the default 250, not a missing value.
   `oc get nodes -o custom-columns=NAME:.metadata.name,CAPACITY:.status.capacity.pods,ALLOCATABLE:.status.allocatable.pods`
3. Print FeatureGate `featureSet` (empty = Default).
   `oc get featuregate cluster -o jsonpath='{.spec.featureSet}{"\n"}'`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#cluster-network-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#cluster-network-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#cluster-network-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#cluster-network-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#cluster-network-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#cluster-network-operator`.

#### Scenario: 7.3.tsr.3_10_kubernetes loads
- WHEN `get_entry` is called with `7.3.tsr.3_10_kubernetes`
- THEN the title is `3.10. Kubernetes`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_10_1_kubeproxy
`load_kb()` SHALL contain `7.3.tsr.3_10_1_kubeproxy` from `7_3_components.toml`. Title SHALL be `3.10.1. KubeProxy`.

description SHALL be:

Validates kube-proxy configuration including proxy mode and iptables/IPVS
settings. On OVN-Kubernetes clusters, kube-proxy functionality is integrated
into OVN and separate proxy config may not apply.

recommendation SHALL be:

On OVN-Kubernetes, keep deployKubeProxy false or empty and no kube-proxy DaemonSet. A kube-proxy row on OVN is a warning. OpenShiftSDN was removed in 4.17.

verification SHALL be:

1. Print network type. OVNKubernetes means kube-proxy is not deployed (TSR and engine N/A). OpenShiftSDN was removed in 4.17:
   `oc get network.config cluster -o jsonpath='{.spec.networkType}{"\n"}'`
2. Print deployKubeProxy (false or <none> is expected on OVN; true deploys standalone kube-proxy):
   `oc get network.operator cluster -o custom-columns=NAME:.metadata.name,TYPE:.spec.defaultNetwork.type,DEPLOY_KUBE_PROXY:.spec.deployKubeProxy`
3. Print kube-proxy DaemonSets (empty = none; any row on OVN is **WARNING**):
   `oc get ds -A | awk 'NR==1 || $2=="kube-proxy"'`
5. https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#about-ovn-kubernetes

impact SHALL be:

workload-shift

impact_scope SHALL be:

kube-proxy DaemonSet if present on OVN

impact_detail SHALL be:

Removing an unexpected kube-proxy DaemonSet on OVN-Kubernetes changes Service dataplane handling on those nodes. It does not reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#cluster-network-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#cluster-network-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#cluster-network-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#cluster-network-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#cluster-network-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#cluster-network-operator`.

#### Scenario: 7.3.tsr.3_10_1_kubeproxy loads
- WHEN `get_entry` is called with `7.3.tsr.3_10_1_kubeproxy`
- THEN the title is `3.10.1. KubeProxy`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_10_2_ovnkube
`load_kb()` SHALL contain `7.3.tsr.3_10_2_ovnkube` from `7_3_components.toml`. Title SHALL be `3.10.2. OVNKube`.

description SHALL be:

Validates OVN-Kubernetes health. The TSR scores ovnkube node CNI request
duration and expects the 95th percentile below 5 seconds. OVN-Kubernetes
provides the cluster networking data plane; slow CNI or a degraded operator
affects pod-to-pod and service communication.

recommendation SHALL be:

Bring the network ClusterOperator to `Available=True`, `Progressing=False`, `Degraded=False` with ovnkube-node `READY=DESIRED`. If the operator or DS is degraded, east-west traffic and Services fail. IPsec is a separate network row.

verification SHALL be:

1. Confirm ClusterOperator network (`Available=True`, `Progressing=False`, `Degraded=False`):
   `oc get co network | awk 'NR==1{print "RESULT",$0; next} {print ($3=="True" && $4=="False" && $5=="False"?"PASS":"FAIL"), $0}'`
2. Confirm ovnkube-node (`READY=DESIRED`) and ovnkube-control-plane (`READY=SPEC`):
   `oc get ds -n openshift-ovn-kubernetes -o custom-columns=NAME:.metadata.name,DESIRED:.status.desiredNumberScheduled,READY:.status.numberReady | awk 'NR==1{print "RESULT",$0; next} {print ($2==$3?"PASS":"FAIL"), $0}'`
   `oc get deploy -n openshift-ovn-kubernetes -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,SPEC:.spec.replicas | awk 'NR==1{print "RESULT",$0; next} {print ($2==$3?"PASS":"FAIL"), $0}'`
3. Review OVN-Kubernetes operator behavior using the link in the reference.

impact SHALL be:

workload-shift

impact_scope SHALL be:

ovnkube-node and cluster networking

impact_detail SHALL be:

Restoring the network ClusterOperator and ovnkube-node READY=DESIRED rolls OVN pods and can interrupt east-west traffic. Do not change networkType in place.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#about-ovn-kubernetes`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#about-ovn-kubernetes`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#about-ovn-kubernetes`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#about-ovn-kubernetes`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#about-ovn-kubernetes`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#about-ovn-kubernetes`.

#### Scenario: 7.3.tsr.3_10_2_ovnkube loads
- WHEN `get_entry` is called with `7.3.tsr.3_10_2_ovnkube`
- THEN the title is `3.10.2. OVNKube`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_10_3_featuregates
`load_kb()` SHALL contain `7.3.tsr.3_10_3_featuregates` from `7_3_components.toml`. Title SHALL be `3.10.3. Featuregates`.

description SHALL be:

Native scoring does not inspect the FeatureGate CR (always SKIPPED). Manual check: non-default feature gates may enable tech-preview features that affect supportability or introduce behavior changes that complicate upgrades.

recommendation SHALL be:

Keep featureSet at Default (empty) unless a non-default set was chosen on purpose. TechPreviewNoUpgrade and CustomNoUpgrade are irreversible and block upgrades.

verification SHALL be:

1. Print the configured feature set. Empty means Default:
   `oc get featuregate cluster -o jsonpath='{.spec.featureSet}{"\n"}'`
2. `TechPreviewNoUpgrade` and `CustomNoUpgrade` are irreversible and block upgrades. Confirm they are intentional.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster-wide

impact_detail SHALL be:

TechPreviewNoUpgrade and CustomNoUpgrade are irreversible and block upgrades. Do not flip featureSet as a trial.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-cluster-enabling-features-about_nodes-cluster-enabling`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-cluster-enabling-features-about_nodes-cluster-enabling`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-cluster-enabling-features-about_nodes-cluster-enabling`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-cluster-enabling-features-about_nodes-cluster-enabling`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-cluster-enabling-features-about_nodes-cluster-enabling`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-cluster-enabling-features-about_nodes-cluster-enabling`.

#### Scenario: 7.3.tsr.3_10_3_featuregates loads
- WHEN `get_entry` is called with `7.3.tsr.3_10_3_featuregates`
- THEN the title is `3.10.3. Featuregates`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_10_4_kubelet_config
`load_kb()` SHALL contain `7.3.tsr.3_10_4_kubelet_config` from `7_3_components.toml`. Title SHALL be `3.10.4. Kubelet-Config`.

description SHALL be:

Validates custom `KubeletConfig` resources that override default kubelet
parameters. Misconfigured kubelet settings can cause node instability,
pod eviction issues, or resource management problems.

recommendation SHALL be:

Change a `KubeletConfig` only when you intend to roll the targeted MCP. An empty list means defaults, including maxPods 250. A patch drains the pool.

verification SHALL be:

1. List kubelet configurations:
   `oc get kubeletconfig -o custom-columns=NAME:.metadata.name,MAXPODS:.spec.kubeletConfig.maxPods,POOL:.spec.machineConfigPoolSelector`
2. Verify `MachineConfigPool` status after changes:
   `oc get mcp`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in targeted MachineConfigPool

impact_detail SHALL be:

`KubeletConfig` changes trigger a MachineConfig update that rolls nodes in the targeted pool one by one.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-managing`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-nodes-managing`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-nodes-managing`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-nodes-managing`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-nodes-managing`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-nodes-managing`.

#### Scenario: 7.3.tsr.3_10_4_kubelet_config loads
- WHEN `get_entry` is called with `7.3.tsr.3_10_4_kubelet_config`
- THEN the title is `3.10.4. Kubelet-Config`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_11_ocp_limits
`load_kb()` SHALL contain `7.3.tsr.3_11_ocp_limits` from `7_3_components.toml`. Title SHALL be `3.11. OCP Limits`.

description SHALL be:

Validates whether the cluster is approaching or exceeding documented OpenShift
scalability limits for nodes, pods, services, or other objects. Exceeding
limits can cause degraded performance or unsupported configurations.

recommendation SHALL be:

Bring every object COUNT to or below the LIMIT printed beside it. Counts above documented OpenShift maximums are an unsupported scale. Pods-per-node versus allocatable is a topology density question.

verification SHALL be:

1. Cluster-wide counts (COUNT / LIMIT; COUNT>LIMIT is **FAIL**):
   `oc get nodes --no-headers | awk 'END{print (NR<=2000?"PASS":"FAIL"), NR+0, "/ 2000 nodes"}' && \
   oc get pods -A --no-headers | awk 'END{print (NR<=150000?"**PASS**":"**FAIL**"), NR+0, "/ 150000 pods"}' && \
   oc get ns --no-headers | awk 'END{print (NR<=10000?"**PASS**":"**FAIL**"), NR+0, "/ 10000 namespaces"}' && \
   oc get svc -A --no-headers | awk 'END{print (NR<=10000?"**PASS**":"**FAIL**"), NR+0, "/ 10000 services"}'`
2. Config object counts:
   `oc get cm -A --no-headers | awk 'END{print (NR<=90000?"PASS":"FAIL"), NR+0, "/ 90000 configmaps"}' && \
   oc get secret -A --no-headers | awk 'END{print (NR<=80000?"**PASS**":"**FAIL**"), NR+0, "/ 80000 secrets"}' && \
   oc get crd --no-headers | awk 'END{print (NR<=1024?"**PASS**":"**FAIL**"), NR+0, "/ 1024 crds"}'`

3. OpenShift object counts:
   `oc get routes -A --no-headers | awk 'END{print (NR<=9000?"PASS":"FAIL"), NR+0, "/ 9000 routes"}' && \
   oc get builds -A --no-headers | awk 'END{print (NR<=10000?"**PASS**":"**FAIL**"), NR+0, "/ 10000 builds"}' && \
   oc get bc -A --no-headers | awk 'END{print (NR<=12000?"**PASS**":"**FAIL**"), NR+0, "/ 12000 buildconfigs"}'`
4. Peak objects in any one namespace:
   `oc get pods -A --no-headers -o custom-columns=NS:.metadata.namespace | awk '{c[$1]++} END{m=0; for (n in c) if (c[n]>m) m=c[n]; print (m<=25000?"PASS":"FAIL"), m+0, "/ 25000 pods-per-ns"}' && \
   oc get svc -A --no-headers -o custom-`columns=NS:.metadata.namespace` | awk '{c[$1]++} END{`m=0`; for (n in c) if (c[n]>m) `m=c`[n]; print (m<=5000?"**PASS**":"**FAIL**"), m+0, "/ 5000 svc-per-ns"}' && \
   oc get deploy -A --no-headers -o custom-`columns=NS:.metadata.namespace` | awk '{c[$1]++} END{`m=0`; for (n in c) if (c[n]>m) `m=c`[n]; print (m<=2000?"**PASS**":"**FAIL**"), m+0, "/ 2000 deploy-per-ns"}'`
5. Peak EndpointSlice backends on any one Service:
   `oc get endpointslice -A -o json | jq -r '[.items[] | {svc: (.metadata.namespace+"/"+(.metadata.labels["kubernetes.io/service-name"] // .metadata.name)), n: ((.endpoints // [])|length)}] | group_by(.svc) | map(map(.n)|add) | max // 0 | (if .<=5000 then "PASS" else "FAIL" end) + " " + tostring + " / 5000 backends-per-svc"'`
7. Compare these counts to the published object maximums using the link in the reference.

impact SHALL be:

workload-shift

impact_scope SHALL be:

objects above documented OpenShift maximums

impact_detail SHALL be:

Bringing counts back under documented limits means deleting or spreading objects and can remove APIs or workloads. Nodes are not rebooted.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#planning-your-environment-according-to-object-maximums`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#planning-your-environment-according-to-object-maximums`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#planning-your-environment-according-to-object-maximums`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#planning-your-environment-according-to-object-maximums`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#planning-your-environment-according-to-object-maximums`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#planning-your-environment-according-to-object-maximums`.

#### Scenario: 7.3.tsr.3_11_ocp_limits loads
- WHEN `get_entry` is called with `7.3.tsr.3_11_ocp_limits`
- THEN the title is `3.11. OCP Limits`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_14_load_balancer
`load_kb()` SHALL contain `7.3.tsr.3_14_load_balancer` from `7_3_components.toml`. Title SHALL be `3.14. Load Balancer`.

description SHALL be:

Parent section covering load balancer configuration including platform load
balancers and MetalLB for bare-metal environments. Proper load balancing
is critical for API and ingress high availability.

recommendation SHALL be:

This section is a section index. Keep a reachable API VIP and, on bare metal, MetalLB or another LB actually assigning IPs. Use platform LB and MetalLB children for scored recommendations.

verification SHALL be:

1. List LoadBalancer services only:
   `oc get svc -A --no-headers -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,IP:.status.loadBalancer.ingress[0].ip | awk '$3=="LoadBalancer" {print}'`
2. Check MetalLB status if deployed:
   `oc get metallb -n metallb-system`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#load-balancing`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#load-balancing`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#load-balancing`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#load-balancing`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#load-balancing`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#load-balancing`.

#### Scenario: 7.3.tsr.3_14_load_balancer loads
- WHEN `get_entry` is called with `7.3.tsr.3_14_load_balancer`
- THEN the title is `3.14. Load Balancer`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_14_1_platform_load_balancer
`load_kb()` SHALL contain `7.3.tsr.3_14_1_platform_load_balancer` from `7_3_components.toml`. Title SHALL be `3.14.1. Platform Load Balancer`.

description SHALL be:

Validates the platform-provided load balancer configuration for API and ingress
VIPs. Misconfigured or unhealthy platform LBs cause API unreachability or
ingress traffic failures.

recommendation SHALL be:

Keep the platform LB (or UserManaged appliance) reaching the API and apps VIPs: `readyz=ok` and console 80/443 returning 200 or 302.

verification SHALL be:

1. Print platform type, loadBalancer.type, and API/ingress VIP counts:
   `oc get infrastructure cluster -o json | jq -r '.status.platformStatus as $ps | ([($ps|to_entries[]) | select(.key != "type" and (.value|type=="object"))][0].value // {}) as $d | (["TYPE","LB","API_VIPS","INGRESS_VIPS"], [$ps.type, ($d.loadBalancer.type // "-"), ((($d.apiServerInternalIPs // (if $d.apiServerInternalIP then [$d.apiServerInternalIP] else [] end)) | length) | tostring), ((($d.ingressIPs // (if $d.ingressIP then [$d.ingressIP] else [] end)) | length) | tostring)]) | @tsv' | column -t -s $'\t'`
2. Probe the API through the kubeconfig path (the API VIP/LB). Expect ok:
   `oc get --raw=/readyz | awk '{print} END{print ($0=="ok"?"PASS":"FAIL"), "api-readyz"}'`
3. Probe ingress 443 and 80 via the console route (apps VIP). Expect 200 or 302:
   `host=$(oc get route -n openshift-console console -o jsonpath='{.spec.host}'); c443=$(curl -sk -o /dev/null -w '%{http_code}' --connect-timeout 10 "https://$host"); c80=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 "http://$host"); printf '443 %s\n80 %s\n' "$c443" "$c80" | awk '$2==200 || $2==302 {ok++} END{print ((ok==2)?"PASS":"FAIL"), "ingress-80-443"}'`
5. User-managed LB probe intervals cannot be read from the cluster. The documented API check is GET /readyz every 5-10s, remove from pool within 30s of failure. Confirm that on the external appliance when LB is UserManaged.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

API and apps VIP / platform load balancer

impact_detail SHALL be:

Repairing the platform or UserManaged load balancer can interrupt API 6443 and ingress until readyz and the console return healthy.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#load-balancing`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#load-balancing`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#load-balancing`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#load-balancing`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#load-balancing`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#load-balancing`.

#### Scenario: 7.3.tsr.3_14_1_platform_load_balancer loads
- WHEN `get_entry` is called with `7.3.tsr.3_14_1_platform_load_balancer`
- THEN the title is `3.14.1. Platform Load Balancer`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_14_2_metallb
`load_kb()` SHALL contain `7.3.tsr.3_14_2_metallb` from `7_3_components.toml`. Title SHALL be `3.14.2. MetalLB`.

description SHALL be:

Parent section covering MetalLB load balancer deployment, configuration, and
protocol settings for bare-metal clusters. MetalLB provides LoadBalancer-type
service support without cloud provider integration.

recommendation SHALL be:

This section is a section index. MetalLB is not applicable unless this cluster uses it for LoadBalancer Services. Use installed, config, and L2 ARP/NDP children when it is in use.

verification SHALL be:

1. List MetalLB CRs:
   `oc get metallb -n metallb-system -o custom-columns=NAME:.metadata.name,LOGLEVEL:.spec.logLevel`
2. Verify speaker and controller pods:
   `oc get pods -n metallb-system`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#about-metallb`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#about-metallb`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#about-metallb`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#about-metallb`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#about-metallb`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#about-metallb`.

#### Scenario: 7.3.tsr.3_14_2_metallb loads
- WHEN `get_entry` is called with `7.3.tsr.3_14_2_metallb`
- THEN the title is `3.14.2. MetalLB`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_14_2_1_metallb_installed
`load_kb()` SHALL contain `7.3.tsr.3_14_2_1_metallb_installed` from `7_3_components.toml`. Title SHALL be `3.14.2.1. Metallb Installed`.

description SHALL be:

Verifies that the MetalLB operator and instance are correctly installed and
running. Without a healthy MetalLB deployment, LoadBalancer-type services on
bare-metal clusters remain in Pending state.

recommendation SHALL be:

Install a healthy MetalLB operator and instance before expecting LoadBalancer Services to get IPs. Keep a Succeeded subscription, a MetalLB CR, and controller/speaker pods Running. Pools and advertisements are a separate config row.

verification SHALL be:

1. Verify MetalLB operator subscription and instance:
   `oc get subscription -n metallb-system`
   `oc get metallb -n metallb-system`
2. Check that controller and speaker pods are running:
   `oc get pods -n metallb-system`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

MetalLB operator, controller, and speaker pods

impact_detail SHALL be:

Installing or repairing MetalLB rolls those pods. LoadBalancer Services wait for IPs; nodes are not rebooted.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#metallb-operator-install`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#metallb-operator-install`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#metallb-operator-install`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#metallb-operator-install`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#metallb-operator-install`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#metallb-operator-install`.

#### Scenario: 7.3.tsr.3_14_2_1_metallb_installed loads
- WHEN `get_entry` is called with `7.3.tsr.3_14_2_1_metallb_installed`
- THEN the title is `3.14.2.1. Metallb Installed`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_14_2_2_lb_metallb_config
`load_kb()` SHALL contain `7.3.tsr.3_14_2_2_lb_metallb_config` from `7_3_components.toml`. Title SHALL be `3.14.2.2. Lb Metallb Config`.

description SHALL be:

Validates MetalLB IP address pool configuration and advertisement settings.
Misconfigured address pools or missing advertisements prevent IP allocation
to LoadBalancer services.

recommendation SHALL be:

Match at least one address pool (with autoAssign unless you pin IPs) and an advertisement that names that pool. A Service without an IP is a pool or advertisement miss, not a speaker crash. Config match or N/A if MetalLB is not in use.

verification SHALL be:

1. Print address pools:
   `oc get ipaddresspool -n metallb-system -o custom-columns=NAME:.metadata.name,ADDRESSES:.spec.addresses,AUTOASSIGN:.spec.autoAssign`
2. Print L2/BGP advertisements:
   `oc get l2advertisement,bgpadvertisement -n metallb-system -o custom-columns=KIND:.kind,NAME:.metadata.name,POOLS:.spec.ipAddressPools`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

MetalLB IP allocation

impact_detail SHALL be:

Address pool changes affect future IP assignments but do not disrupt existing allocated IPs or restart nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#metallb-configure-address-pools`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#metallb-configure-address-pools`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#metallb-configure-address-pools`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#metallb-configure-address-pools`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#metallb-configure-address-pools`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#metallb-configure-address-pools`.

#### Scenario: 7.3.tsr.3_14_2_2_lb_metallb_config loads
- WHEN `get_entry` is called with `7.3.tsr.3_14_2_2_lb_metallb_config`
- THEN the title is `3.14.2.2. Lb Metallb Config`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_14_2_3_metallb_l2_arp_ndp
`load_kb()` SHALL contain `7.3.tsr.3_14_2_3_metallb_l2_arp_ndp` from `7_3_components.toml`. Title SHALL be `3.14.2.3. MetalLB L2 ARP/NDP`.

description SHALL be:

Checks MetalLB Layer 2 mode ARP/NDP advertisement configuration and speaker
health. L2 mode relies on ARP (IPv4) or NDP (IPv6) to announce VIPs, and
misconfiguration causes unreachable services.

recommendation SHALL be:

Keep an L2Advertisement covering the pool and speakers Running on the nodes that should own the VIP. If the Service has an IP but is unreachable, check speaker placement and logs before changing the pool.

verification SHALL be:

1. Print L2 advertisements:
   `oc get l2advertisement -n metallb-system -o custom-columns=NAME:.metadata.name,POOLS:.spec.ipAddressPools,INTERFACES:.spec.interfaces`
2. Verify speaker pods are running on all nodes:
   `oc get pods -n metallb-system -l component=speaker -o wide`
3. Check speaker logs for ARP/NDP errors.

impact SHALL be:

workload-shift

impact_scope SHALL be:

L2 VIP ownership and speaker placement

impact_detail SHALL be:

Moving speakers or fixing L2Advertisement can briefly move the VIP between nodes. It does not reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#metallb-configure-l2-advertisement`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#metallb-configure-l2-advertisement`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#metallb-configure-l2-advertisement`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#metallb-configure-l2-advertisement`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#metallb-configure-l2-advertisement`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#metallb-configure-l2-advertisement`.

#### Scenario: 7.3.tsr.3_14_2_3_metallb_l2_arp_ndp loads
- WHEN `get_entry` is called with `7.3.tsr.3_14_2_3_metallb_l2_arp_ndp`
- THEN the title is `3.14.2.3. MetalLB L2 ARP/NDP`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_15_machine_config_pool
`load_kb()` SHALL contain `7.3.tsr.3_15_machine_config_pool` from `7_3_components.toml`. Title SHALL be `3.15. Machine Config Pool`.

description SHALL be:

Validates `MachineConfigPool` status including update progress, degraded nodes,
and configuration drift. Degraded or paused MCPs indicate nodes that are not
applying the desired machine configuration.

recommendation SHALL be:

Ensure every `MachineConfigPool` is in a stable state: `UPDATED=True`, `UPDATING=False`, `DEGRADED=False`, `spec.paused=false`, and machine counts that match the pool's expected membership. Investigate any paused pool before a cluster upgrade, because it prevents the Machine Config Operator from applying configuration updates.

verification SHALL be:

1. Confirm each pool from the stock table (`UPDATED=True`, `UPDATING=False`, `DEGRADED=False`, `MACHINECOUNT=READYMACHINECOUNT`=UPDATEDMACHINECOUNT, `DEGRADEDMACHINECOUNT=0`). `UPDATING=True` is **WARNING**:
   `oc get mcp | awk 'NR==1{print "RESULT",$0; next} {r="FAIL"; if ($5=="True" || $9+0>0 || $3!="True" || $6!=$7 || $6!=$8) r="FAIL"; else if ($4=="True") r="WARNING"; else r="PASS"; print r, $0}'`
2. Confirm paused (true needs action):
   `oc get mcp -o custom-columns=NAME:.metadata.name,PAUSED:.spec.paused | awk 'NR==1{print "RESULT",$0; next} {print ($2=="true"?"FAIL":"PASS"), $0}'`
3. Membership: master MACHINES should equal master-labeled nodes; worker MACHINES should equal worker-only nodes (compact: `worker=0` because masters also have the worker role):
   `oc get mcp -o custom-columns=NAME:.metadata.name,MACHINES:.status.machineCount && \
   oc get nodes -l node-role.kubernetes.io/master --no-headers | awk 'END{print NR+0, "master-labeled"}' && \
   oc get nodes -l 'node-role.kubernetes.io/worker,!node-role.kubernetes.io/master' --no-headers 2>/dev/null | awk 'END{print NR+0, "worker-only"}'`
4. If `DEGRADED=True`, print reason/message (empty = none):
   `oc get mcp -o json | jq -r '.items[] | .metadata.name as $n | .status.conditions[]? | select(.type=="Degraded" and .status=="True") | [$n, (.reason // "-"), (.message // "-")] | @tsv'`
5. Confirm unique nodeSelector per pool:
   `oc get mcp -o json | jq -r '[.items[] | .spec.nodeSelector|tostring] | group_by(.) | map(select(length>1)) | if length==0 then "PASS unique-nodeSelectors" else "FAIL duplicate-nodeSelectors" end'`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the paused, degraded, or updating pool

impact_detail SHALL be:

Resolving MCP degradation may require the MCO to drain and reboot stuck nodes to complete configuration rollout.

`include_in_findings` SHALL be false.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`.

#### Scenario: 7.3.tsr.3_15_machine_config_pool loads
- WHEN `get_entry` is called with `7.3.tsr.3_15_machine_config_pool`
- THEN the title is `3.15. Machine Config Pool`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_16_stream_control_transmission_protocol_sctp
`load_kb()` SHALL contain `7.3.tsr.3_16_stream_control_transmission_protocol_sctp` from `7_3_components.toml`. Title SHALL be `3.16. Stream Control Transmission Protocol (SCTP)`.

description SHALL be:

Checks whether SCTP protocol support is enabled on the cluster via
MachineConfig. SCTP is required for telco workloads but is not enabled by
default and requires kernel module loading on nodes.

recommendation SHALL be:

Do not enable SCTP unless an application requires it. If required, keep load-sctp MachineConfig present and lsmod showing sctp on the target nodes. No sctp MachineConfig means the feature is unused.

verification SHALL be:

1. Check if SCTP is enabled by looking for the load-sctp MachineConfig:
   `oc get mc | grep sctp`
2. Verify the kernel module is loaded on target nodes:
   `oc debug node/<node> -- chroot /host lsmod | grep sctp`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes targeted by the load-sctp MachineConfig

impact_detail SHALL be:

Enabling SCTP applies a MachineConfig that drains and reboots the targeted nodes one at a time. Leave SCTP unused when no application requires it.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#nw-sctp-about_using-sctp`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#nw-sctp-about_using-sctp`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#nw-sctp-about_using-sctp`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#nw-sctp-about_using-sctp`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#nw-sctp-about_using-sctp`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#nw-sctp-about_using-sctp`.

#### Scenario: 7.3.tsr.3_16_stream_control_transmission_protocol_sctp loads
- WHEN `get_entry` is called with `7.3.tsr.3_16_stream_control_transmission_protocol_sctp`
- THEN the title is `3.16. Stream Control Transmission Protocol (SCTP)`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_17_network
`load_kb()` SHALL contain `7.3.tsr.3_17_network` from `7_3_components.toml`. Title SHALL be `3.17. Network`.

description SHALL be:

Parent section covering cluster networking configuration including IP stack,
IPsec, multiple networks, hardware networks, bond/VLAN configuration, and
consistency checks.

recommendation SHALL be:

This section is a section index. Keep a matching network.operator and NNCP state Available where nmstate is in use. Use the IP-stack through VLAN children for scored recommendations.

verification SHALL be:

1. Print cluster network type and CIDRs:
   `oc get network.config cluster -o custom-columns=TYPE:.spec.networkType,CLUSTER:.spec.clusterNetwork[*].cidr,SERVICE:.spec.serviceNetwork[*]`
2. Print network.operator conditions:
   `oc get network.operator cluster -o jsonpath='{.spec.defaultNetwork.type}{"\n"}{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'`
3. List NodeNetworkConfigurationPolicy state:
   `oc get nncp -o custom-columns=NAME:.metadata.name,STATE:.status.state`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#understanding-networking`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#understanding-networking`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#understanding-networking`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#understanding-networking`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#understanding-networking`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#understanding-networking`.

#### Scenario: 7.3.tsr.3_17_network loads
- WHEN `get_entry` is called with `7.3.tsr.3_17_network`
- THEN the title is `3.17. Network`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_17_1_ip_stack
`load_kb()` SHALL contain `7.3.tsr.3_17_1_ip_stack` from `7_3_components.toml`. Title SHALL be `3.17.1. IP Stack`.

description SHALL be:

Identifies whether the cluster is configured for single-stack (IPv4 or IPv6)
or dual-stack networking. The IP stack choice affects service CIDR allocation,
pod networking, and external connectivity patterns.

recommendation SHALL be:

Keep the installed IP family. Changing clusterNetwork and serviceNetwork after install is a rebuild, not a day-2 patch. Dual-stack shows both CIDRs.

verification SHALL be:

1. Check IP stack configuration:
   `oc get network cluster -o jsonpath='{.spec.clusterNetwork}'`
   `oc get network cluster -o jsonpath='{.spec.serviceNetwork}'`
2. Dual-stack clusters will show entries for both IPv4 and IPv6 CIDRs.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster rebuild

impact_detail SHALL be:

Changing clusterNetwork or serviceNetwork after install is a rebuild, not a day-2 patch.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#nw-operator-cr-ip-address-family`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#nw-operator-cr-ip-address-family`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#nw-operator-cr-ip-address-family`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#nw-operator-cr-ip-address-family`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#nw-operator-cr-ip-address-family`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#nw-operator-cr-ip-address-family`.

#### Scenario: 7.3.tsr.3_17_1_ip_stack loads
- WHEN `get_entry` is called with `7.3.tsr.3_17_1_ip_stack`
- THEN the title is `3.17.1. IP Stack`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_17_2_ipsec_encryption
`load_kb()` SHALL contain `7.3.tsr.3_17_2_ipsec_encryption` from `7_3_components.toml`. Title SHALL be `3.17.2. IPsec Encryption`.

description SHALL be:

Checks whether IPsec encryption is enabled for pod-to-pod traffic. IPsec
provides network-level encryption for compliance requirements but adds
CPU overhead and latency to network communication.

recommendation SHALL be:

Leave IPsec empty or disabled unless a compliance requirement says otherwise. If enabled, keep the config complete and budget node CPU. Do not toggle IPsec as a troubleshooting step.

verification SHALL be:

1. Check IPsec configuration:
   `oc get network.operator cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.ipsecConfig}'`
2. Review node performance impact if enabled and verify certificates are valid.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

node CPU and overlay traffic

impact_detail SHALL be:

Network-plugin migration changes cluster networking behavior and can disrupt pod and service traffic if not executed in a planned maintenance window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#nw-ovn-ipsec-about_configuring-ipsec-ovn`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#nw-ovn-ipsec-about_configuring-ipsec-ovn`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#nw-ovn-ipsec-about_configuring-ipsec-ovn`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#nw-ovn-ipsec-about_configuring-ipsec-ovn`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#nw-ovn-ipsec-about_configuring-ipsec-ovn`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#nw-ovn-ipsec-about_configuring-ipsec-ovn`.

#### Scenario: 7.3.tsr.3_17_2_ipsec_encryption loads
- WHEN `get_entry` is called with `7.3.tsr.3_17_2_ipsec_encryption`
- THEN the title is `3.17.2. IPsec Encryption`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_17_3_multiple_networks
`load_kb()` SHALL contain `7.3.tsr.3_17_3_multiple_networks` from `7_3_components.toml`. Title SHALL be `3.17.3. Multiple Networks`.

description SHALL be:

Validates additional network attachment definitions for secondary pod networks.
Multiple networks enable traffic isolation, dedicated storage networks, or
telco-specific data plane separation.

recommendation SHALL be:

Print CNO additional names, then NAD type/IPAM, when extra networks are in the design. Empty additionalNetworks means extra networks are not in use, not a failure. A cnv-bridge NAD needs the linux-bridge CNI DaemonSet.

verification SHALL be:

1. Print CNO additional network names/types. Empty is **INFO**, not **FAIL**:
   `oc get network.operator cluster -o jsonpath='{range .spec.additionalNetworks[*]}{.name}{"\t"}{.namespace}{"\t"}{.type}{"\n"}{end}'`
2. Print NAD CNI type and IPAM (INVALID = config is not JSON). openshift-ovn-kubernetes/default type ovn-k8s-cni-overlay is the primary CNI, not an extra network.
   `oc get net-attach-def -A -o json | jq -r '.items[] | .spec.config as $raw | (try ($raw|fromjson) catch null) as $c | [.metadata.namespace, .metadata.name, (if $c==null then "INVALID" else ($c.type // ([$c.plugins[]?.type]|join(",")) // "-") end), (if $c==null then "-" else ($c.ipam.type // $c.plugins[0].ipam.type // "-") end)] | @tsv'`
3. Multus enabled (`disableMultiNetwork=true` means Multus is off). DaemonSet `READY=DESIRED` from the stock table:
   `oc get network.operator cluster -o jsonpath='{.spec.disableMultiNetwork}{"\n"}' && \
   oc get ds -n openshift-multus`
4. If step 2 listed type cnv-bridge, same for linux-bridge CNI (empty needs action when those NADs exist):
   `oc get ds -n openshift-cnv`

impact SHALL be:

workload-shift

impact_scope SHALL be:

additional NAD and linux-bridge CNI pods

impact_detail SHALL be:

Standing up an extra network or the linux-bridge DaemonSet rolls those pods. Empty additionalNetworks is not a failure.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#understanding-multiple-networks`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#understanding-multiple-networks`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#understanding-multiple-networks`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#understanding-multiple-networks`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#understanding-multiple-networks`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#understanding-multiple-networks`.

#### Scenario: 7.3.tsr.3_17_3_multiple_networks loads
- WHEN `get_entry` is called with `7.3.tsr.3_17_3_multiple_networks`
- THEN the title is `3.17.3. Multiple Networks`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_17_4_hardware_networks
`load_kb()` SHALL contain `7.3.tsr.3_17_4_hardware_networks` from `7_3_components.toml`. Title SHALL be `3.17.4. Hardware Networks`.

description SHALL be:

Checks for SR-IOV or other hardware network device configurations. Hardware
networks provide high-performance, low-latency networking for specialized
workloads like NFV and HPC.

recommendation SHALL be:

If SR-IOV policies exist, bring node-state SYNC to Succeeded and make interface names match the policy. Empty policies means SR-IOV is not in use. A mismatch is a VF that will not attach.

verification SHALL be:

1. List SR-IOV policies:
   `oc get sriovnetworknodepolicies -n openshift-sriov-network-operator`
2. Print node-state sync and interface names:
   `oc get sriovnetworknodestates -n openshift-sriov-network-operator -o custom-columns=NAME:.metadata.name,SYNC:.status.syncStatus,IFS:.status.interfaces[*].name`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

SR-IOV-capable workers and attached VFs

impact_detail SHALL be:

Updating SR-IOV policies reprovisions virtual functions on the NIC and can interrupt workloads attached to those interfaces until reconciliation completes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#about-sriov`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#about-sriov`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#about-sriov`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#about-sriov`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#about-sriov`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#about-sriov`.

#### Scenario: 7.3.tsr.3_17_4_hardware_networks loads
- WHEN `get_entry` is called with `7.3.tsr.3_17_4_hardware_networks`
- THEN the title is `3.17.4. Hardware Networks`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_17_5_network_config_consistent
`load_kb()` SHALL contain `7.3.tsr.3_17_5_network_config_consistent` from `7_3_components.toml`. Title SHALL be `3.17.5. Network Config Consistent`.

description SHALL be:

Validates that node network configurations are consistent across nodes in the
same role. Inconsistent network config can cause routing asymmetry, DNS
failures, and unpredictable connectivity issues.

recommendation SHALL be:

Where NNCP exists, bring it to Available. Progressing is a rollout; Degraded is a failed enactment. Missing CRDs means host NICs are not NNCP-managed.

verification SHALL be:

1. List kubernetes-nmstate CRDs. If neither CRD exists, host NICs are not managed by nmstate and this check does not apply:
   `oc get crd nodenetworkconfigurationpolicies.nmstate.io nodenetworkconfigurationenactments.nmstate.io -o name --ignore-not-found | awk '{print; n++} END{print (n==2?"PASS nmstate-crds":"INFO n/a-nmstate")}'`
2. Confirm each NodeNetworkConfigurationPolicy from the stock table (`STATUS=Available` is **PASS**, Progressing is **WARNING**, Degraded is **FAIL**):
   `oc get nncp | awk 'NR==1{print "RESULT",$0; next} {n++; r="FAIL"; if ($2=="Available") r="PASS"; else if ($2=="Progressing") r="WARNING"; print r, $0} END{if (n==0) print "INFO 0 nncp"}'`
3. Confirm each NodeNetworkConfigurationEnactment the same way.
   `oc get nnce | awk 'NR==1{print "RESULT",$0; next} {n++; r="FAIL"; if ($2=="Available") r="PASS"; else if ($2=="Progressing") r="WARNING"; print r, $0} END{if (n==0) print "INFO 0 nnce"}'`
4. Review the Kubernetes NMState Operator using the link in the reference.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

nodes targeted by NNCP

impact_detail SHALL be:

Applying or correcting NNCPs can briefly disrupt host networking; use controlled rollout settings such as `maxUnavailable` and validate rollback behavior.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`.

#### Scenario: 7.3.tsr.3_17_5_network_config_consistent loads
- WHEN `get_entry` is called with `7.3.tsr.3_17_5_network_config_consistent`
- THEN the title is `3.17.5. Network Config Consistent`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_17_6_network_bond_configuration
`load_kb()` SHALL contain `7.3.tsr.3_17_6_network_bond_configuration` from `7_3_components.toml`. Title SHALL be `3.17.6. Network Bond Configuration`.

description SHALL be:

This check reviews host bond configuration. A typical warning is active-backup (or equivalent) where only one slave carries traffic, so the bond does not share load.

recommendation SHALL be:

Use 802.3ad (LACP) or balance-xor with at least two links when the design requires both redundancy and load sharing; these supported kernel bond modes require corresponding switch-side aggregation configuration. Use active-backup when simple failover is the objective, as it provides redundancy but sends traffic through only one active link. For OVS-based bonding, balance-slb is also supported for source load balancing on suitable bridge designs.

verification SHALL be:

1. Confirm the install-config ConfigMap exists. If it is missing, day-0 bond data cannot be read:
   `oc get cm cluster-config-v1 -n kube-system`
2. List day-0 bond name, mode, and port count from install-config. Active-backup or fewer than two ports is a warning; a load-sharing mode with at least two ports is healthy:
   `oc get cm cluster-config-v1 -n kube-system -o jsonpath='{.data.install-config}' | python3 -c 'import sys,yaml,json; json.dump(yaml.safe_load(sys.stdin) or {}, sys.stdout)' | jq -r '.platform | to_entries[] | select(.value|type=="object") | (.value.hosts // [])[] | (.networkConfig.interfaces // [])[] | select(.type=="bond") | [.name // "-", (.["link-aggregation"].mode // "-"), ((.["link-aggregation"].port // .["link-aggregation"].ports // [])|length)] | @tsv' | awk 'BEGIN{print "RESULT\tNAME\tMODE\tPORTS"} {r="WARNING"; if ($2!="active-backup" && $2!="active_backup" && $2!="-" && $3+0>=2) r="PASS"; print r"\t"$0} END{if(NR==0) print "INFO\t-\t-\t0"}' | column -t`
3. Count unique NAME/MODE/PORTS fingerprints. The count shows how many hosts share that bond layout:
   `oc get cm cluster-config-v1 -n kube-system -o jsonpath='{.data.install-config}' | python3 -c 'import sys,yaml,json; json.dump(yaml.safe_load(sys.stdin) or {}, sys.stdout)' | jq -r '.platform | to_entries[] | select(.value|type=="object") | (.value.hosts // [])[] | (.networkConfig.interfaces // [])[] | select(.type=="bond") | [.name // "-", (.["link-aggregation"].mode // "-"), ((.["link-aggregation"].port // .["link-aggregation"].ports // [])|length)] | @tsv' | sort | uniq -c | column -t`
4. Day-2 NNCP bonds. If the CRD or resources do not exist, NNCP is not in use:
   `oc get nncp -o json | jq -r '["NNCP","NAME","MODE","PORTS"], (.items[] | .metadata.name as $p | .spec.desiredState.interfaces[]? | select(.type=="bond") | [$p, .name, (.["link-aggregation"].mode // "-"), ((.["link-aggregation"].port // .["link-aggregation"].ports // [])|length)]) | @tsv' | column -t`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

bonded host interfaces and attached workloads

impact_detail SHALL be:

Changing bond mode or switch aggregation can drop that node's connectivity until LACP or failover is correct and should be performed in a planned window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`.

#### Scenario: 7.3.tsr.3_17_6_network_bond_configuration loads
- WHEN `get_entry` is called with `7.3.tsr.3_17_6_network_bond_configuration`
- THEN the title is `3.17.6. Network Bond Configuration`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_17_7_network_vlan_configuration
`load_kb()` SHALL contain `7.3.tsr.3_17_7_network_vlan_configuration` from `7_3_components.toml`. Title SHALL be `3.17.7. Network VLAN Configuration`.

description SHALL be:

Reviews VLAN interface configurations on cluster nodes. VLANs provide network
segmentation for storage, management, and workload traffic isolation.

recommendation SHALL be:

Give VLAN interfaces an ID and a base NIC. A missing either is a dead subinterface. Score day-0 install-config first, then day-2 NNCP. One NAME with two ID/BASE pairs is drift.

verification SHALL be:

1. Confirm the install-config ConfigMap exists. If it is missing, day-0 VLAN data cannot be read:
   `oc get cm cluster-config-v1 -n kube-system`
2. Print day-0 VLAN NAME, ID, and BASE for each host. A missing ID or BASE is a failure:
   `oc get cm cluster-config-v1 -n kube-system -o jsonpath='{.data.install-config}' | python3 -c 'import sys,yaml,json; json.dump(yaml.safe_load(sys.stdin) or {}, sys.stdout)' | jq -r '.platform | to_entries[] | select(.value|type=="object") | (.value.hosts // [])[] | (.networkConfig.interfaces // [])[] | select(.type=="vlan") | [.name // "-", ((.vlan.id // "-")|tostring), (.vlan["base-iface"] // .vlan.baseIface // "-")] | @tsv' | awk 'BEGIN{print "RESULT\tNAME\tID\tBASE"} {r="PASS"; if ($2=="-" || $3=="-") r="FAIL"; print r"\t"$0} END{if(NR==0) print "INFO\t-\t-\t-"}' | column -t`
3. Count unique NAME/ID/BASE fingerprints. One NAME with two ID/BASE pairs means drift across hosts. One line means every host matches:
   `oc get cm cluster-config-v1 -n kube-system -o jsonpath='{.data.install-config}' | python3 -c 'import sys,yaml,json; json.dump(yaml.safe_load(sys.stdin) or {}, sys.stdout)' | jq -r '.platform | to_entries[] | select(.value|type=="object") | (.value.hosts // [])[] | (.networkConfig.interfaces // [])[] | select(.type=="vlan") | [.name // "-", ((.vlan.id // "-")|tostring), (.vlan["base-iface"] // .vlan.baseIface // "-")] | @tsv' | sort | uniq -c | column -t`
4. Day-2 NNCP VLANs. If the CRD or resources do not exist, NNCP is not in use:
   `oc get nncp -o json | jq -r '["NNCP","NAME","ID","BASE"], (.items[] | .metadata.name as $p | .spec.desiredState.interfaces[]? | select(.type=="vlan") | [$p, .name, ((.vlan.id // "-")|tostring), (.vlan["base-iface"] // .vlan.baseIface // "-")]) | @tsv' | column -t`
5. If both sources are empty, VLANs are not in use.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

VLAN subinterfaces

impact_detail SHALL be:

Fixing a missing VLAN ID or base NIC can drop the subinterface until NNCP or day-0 config is corrected and should be performed in a planned window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#k8s-nmstate-about-the-kubernetes-nmstate-operator`.

#### Scenario: 7.3.tsr.3_17_7_network_vlan_configuration loads
- WHEN `get_entry` is called with `7.3.tsr.3_17_7_network_vlan_configuration`
- THEN the title is `3.17.7. Network VLAN Configuration`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_18_cluster_capabilities
`load_kb()` SHALL contain `7.3.tsr.3_18_cluster_capabilities` from `7_3_components.toml`. Title SHALL be `3.18. Cluster Capabilities`.

description SHALL be:

Reviews enabled and disabled cluster capabilities (formerly known as optional
components). Disabled capabilities reduce attack surface and resource usage
but limit available platform features.

recommendation SHALL be:

Match baselineCapabilitySet plus additionalEnabledCapabilities to the install intent. A name in known but not enabled is an intentional disable, not a failure. Empty baseline is vCurrent.

verification SHALL be:

1. Print baseline, additional, enabled, known:
   `oc get clusterversion version -o json | jq '{baseline: .spec.capabilities.baselineCapabilitySet, additional: .spec.capabilities.additionalEnabledCapabilities, enabled: .status.capabilities.enabledCapabilities, known: .status.capabilities.knownCapabilities}'`
      Empty baseline is default vCurrent (every known optional capability). Any name in known but not enabled is **INFO** (intentional shrink), not **FAIL**.
2. If the lists are hard to compare, print only the disabled set:
   `oc get clusterversion version -o json | jq -r '((.status.capabilities.knownCapabilities // []) - (.status.capabilities.enabledCapabilities // [])) | if length==0 then "PASS none-disabled" else "INFO disabled="+join(",") end'`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installation_configuration/index#cluster-capabilities`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installation_configuration/index#cluster-capabilities`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installation_configuration/index#cluster-capabilities`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installation_configuration/index#cluster-capabilities`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installation_configuration/index#cluster-capabilities`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installation_configuration/index#cluster-capabilities`.

#### Scenario: 7.3.tsr.3_18_cluster_capabilities loads
- WHEN `get_entry` is called with `7.3.tsr.3_18_cluster_capabilities`
- THEN the title is `3.18. Cluster Capabilities`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_19_sandboxed_containers_workloads
`load_kb()` SHALL contain `7.3.tsr.3_19_sandboxed_containers_workloads` from `7_3_components.toml`. Title SHALL be `3.19. Sandboxed Containers Workloads`.

description SHALL be:

Checks whether OpenShift sandboxed containers (Kata Containers) are deployed
and configured. Sandboxed containers provide VM-level isolation for untrusted
or multi-tenant workloads.

recommendation SHALL be:

If Kata is installed, make the KataConfig selector match the intended MCP and list kata on RuntimeClass before scheduling sandboxed pods. Empty CSV or KataConfig means the feature is not installed.

verification SHALL be:

1. Check for the sandboxed containers operator:
   `oc get csv -A | grep sandboxed`
2. Print KataConfig selector:
   `oc get kataconfig -o custom-columns=NAME:.metadata.name,SELECTOR:.spec.kataConfigPoolSelector`
3. Review runtimeclass availability:
   `oc get runtimeclass | grep kata`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

MCP selected by KataConfig

impact_detail SHALL be:

`KubeletConfig` changes trigger a MachineConfig update that rolls nodes in the targeted pool one by one.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/openshift_sandboxed_containers/index#about-sandboxed-containers`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/openshift_sandboxed_containers/index#about-sandboxed-containers`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/openshift_sandboxed_containers/index#about-sandboxed-containers`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/openshift_sandboxed_containers/index#about-sandboxed-containers`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/openshift_sandboxed_containers/index#about-sandboxed-containers`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/openshift_sandboxed_containers/index#about-sandboxed-containers`.

#### Scenario: 7.3.tsr.3_19_sandboxed_containers_workloads loads
- WHEN `get_entry` is called with `7.3.tsr.3_19_sandboxed_containers_workloads`
- THEN the title is `3.19. Sandboxed Containers Workloads`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_20_linux_cgroups_version
`load_kb()` SHALL contain `7.3.tsr.3_20_linux_cgroups_version` from `7_3_components.toml`. Title SHALL be `3.20. Linux Cgroups Version`.

description SHALL be:

Identifies whether the cluster nodes use cgroups v1 or v2. OCP 4.14+ defaults
to cgroups v2 which provides better resource isolation but may break workloads
that depend on cgroups v1 filesystem paths.

recommendation SHALL be:

Treat cgroup v1 as a documented exception, not an automatic fix. Switching v1 to v2 (or back) reboots every node. Empty or v2 is the 4.14+ default.

verification SHALL be:

1. Print cluster cgroupMode (empty or v2 is the 4.14+ default; v1 is legacy):
   `oc get nodes.config cluster -o custom-columns=NAME:.metadata.name,CGROUP:.spec.cgroupMode | awk 'NR==1{print; next} {print; m=$2} END{if (m=="<none>" || m=="v2") print "PASS cgroup-v2"; else if (m=="v1") print "WARNING cgroup-v1"; else print "FAIL unknown-cgroupMode"}'`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

every node

impact_detail SHALL be:

Switching cgroup versions is applied through Machine Config and drains and reboots affected nodes one at a time. On compact 3-node clusters where all nodes serve as both control-plane and worker, this affects 100% of cluster capacity.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-cluster-cgroups-2_nodes-cluster-cgroups-2`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-cluster-cgroups-2_nodes-cluster-cgroups-2`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-cluster-cgroups-2_nodes-cluster-cgroups-2`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-cluster-cgroups-2_nodes-cluster-cgroups-2`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-cluster-cgroups-2_nodes-cluster-cgroups-2`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-cluster-cgroups-2_nodes-cluster-cgroups-2`.

#### Scenario: 7.3.tsr.3_20_linux_cgroups_version loads
- WHEN `get_entry` is called with `7.3.tsr.3_20_linux_cgroups_version`
- THEN the title is `3.20. Linux Cgroups Version`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_21_deployment_config_usage
`load_kb()` SHALL contain `7.3.tsr.3_21_deployment_config_usage` from `7_3_components.toml`. Title SHALL be `3.21. Deployment Config Usage`.

description SHALL be:

Detects usage of the deprecated DeploymentConfig API. DeploymentConfigs are
replaced by Kubernetes Deployments and will be removed in a future OCP release.
Migration should be planned proactively.

recommendation SHALL be:

Migrate remaining DeploymentConfigs to Kubernetes Deployment plus ImageStreamTag triggers. An empty oc get dc -A is healthy. Copy image and config triggers before the API is removed.

verification SHALL be:

1. List all DeploymentConfigs and plan migration to Kubernetes Deployments:
   `oc get dc -A`
2. Review each DC for OCP-specific triggers (image change, config change) and replicate equivalent behavior using Deployments and image stream tags where needed.

impact SHALL be:

workload-shift

impact_scope SHALL be:

migrated application workloads

impact_detail SHALL be:

Cutting over from DeploymentConfig to Deployment triggers an application rollout and may reschedule or restart pods during migration.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/building_applications/index#deployment-operations`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/building_applications/index#deployment-operations`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/building_applications/index#deployment-operations`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/building_applications/index#deployment-operations`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/building_applications/index#deployment-operations`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/building_applications/index#deployment-operations`.

#### Scenario: 7.3.tsr.3_21_deployment_config_usage loads
- WHEN `get_entry` is called with `7.3.tsr.3_21_deployment_config_usage`
- THEN the title is `3.21. Deployment Config Usage`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_22_workload_partitioning
`load_kb()` SHALL contain `7.3.tsr.3_22_workload_partitioning` from `7_3_components.toml`. Title SHALL be `3.22. Workload Partitioning`.

description SHALL be:

Parent section covering workload partitioning configuration that pins platform
workloads to specific CPUs, freeing remaining cores for application use.
Critical for telco and real-time workloads.

recommendation SHALL be:

This section is a section index. None or empty means partitioning is off; AllNodes means it is on. Use enabled, MCP match, status, and configuration children for scored recommendations.

verification SHALL be:

1. Print cpuPartitioning. None or empty means workload partitioning is off (not CPU pinning). AllNodes means it is on;
   `oc get infrastructure cluster -o custom-columns=NAME:.metadata.name,CPU_PARTITIONING:.status.cpuPartitioning | awk 'NR==1{print; next} {print; p=$2} END{if (p=="AllNodes") print "INFO partitioning-on"; else print "INFO partitioning-off"}'`
2.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#workload-partitioning`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#workload-partitioning`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#workload-partitioning`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#workload-partitioning`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#workload-partitioning`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#workload-partitioning`.

#### Scenario: 7.3.tsr.3_22_workload_partitioning loads
- WHEN `get_entry` is called with `7.3.tsr.3_22_workload_partitioning`
- THEN the title is `3.22. Workload Partitioning`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_22_1_workload_partitioning_enabled
`load_kb()` SHALL contain `7.3.tsr.3_22_1_workload_partitioning_enabled` from `7_3_components.toml`. Title SHALL be `3.22.1. Workload Partitioning Enabled`.

description SHALL be:

Validates that workload partitioning is enabled at install time and properly
configured. Workload partitioning must be set during installation and cannot
be enabled post-install.

recommendation SHALL be:

Treat cpuPartitioning as install-time only. AllNodes means platform pods are pinned to reserved CPUs; anything else means partitioning is off. Enabling it post-install is a rebuild, not a CR.

verification SHALL be:

1. Verify workload partitioning is enabled by checking the infrastructure resource:
   `oc get infrastructure cluster -o jsonpath='{.status.cpuPartitioning}'`
2. A value of 'AllNodes' indicates workload partitioning is active.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster rebuild

impact_detail SHALL be:

cpuPartitioning is install-time. Enabling AllNodes post-install is a rebuild, not a CR patch.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#workload-partitioning`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#workload-partitioning`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#workload-partitioning`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#workload-partitioning`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#workload-partitioning`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#workload-partitioning`.

#### Scenario: 7.3.tsr.3_22_1_workload_partitioning_enabled loads
- WHEN `get_entry` is called with `7.3.tsr.3_22_1_workload_partitioning_enabled`
- THEN the title is `3.22.1. Workload Partitioning Enabled`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_22_2_performance_profile_match_mcp
`load_kb()` SHALL contain `7.3.tsr.3_22_2_performance_profile_match_mcp` from `7_3_components.toml`. Title SHALL be `3.22.2. Performance Profile Match MCP`.

description SHALL be:

Validates that PerformanceProfile node selectors correctly target the intended
`MachineConfigPool`. Mismatched selectors can leave nodes without performance
tuning or apply tuning to unintended nodes.

recommendation SHALL be:

Make each PerformanceProfile NODESELECTOR match exactly one MCP. No CRD or profile means PerformanceProfiles are not in use. None means MachineConfigs will not apply; two or more can tune the wrong nodes.

verification SHALL be:

1. List PerformanceProfiles. If no CRD or profiles exist, PerformanceProfiles are not in use and this check is done.
   `oc get performanceprofile -A 2>&1 | awk '/No resources found|have a resource type/{print "INFO n/a-performanceprofile"; n=1; next} {print} END{if(!n && NR==0) print "INFO n/a-performanceprofile"}'`
2. Print each profile's nodeSelector as `key=value`. That is the node label the profile applies to:
   `oc get performanceprofile -A -o json | jq -r '["PROFILE","NODESELECTOR"], (.items[] | [.metadata.name, ((.spec.nodeSelector // {})|to_entries|map(.key+"="+(.value|tostring))|sort|join(","))]) | @tsv' | column -t`
3. Print each MCP's nodeSelector matchLabels as `key=value`. That is the node label the pool owns:
   `oc get mcp -o json | jq -r '["MCP","NODESELECTOR"], (.items[] | [.metadata.name, ((.spec.nodeSelector.matchLabels // {})|to_entries|map(.key+"="+(.value|tostring))|sort|join(","))]) | @tsv' | column -t`
4. Compare the NODESELECTOR strings. The profile should match exactly one MCP. If it matches none, MachineConfigs will not roll to those nodes. If it matches two or more, the selector is too broad and can tune the wrong nodes.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

MCP selected by the PerformanceProfile

impact_detail SHALL be:

A selector that matches none or two pools can tune the wrong nodes. Correcting it applies MachineConfig and drains and reboots the intended pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#about-hyperthreading-for-low-latency-and-real-time-applications_cnf-understanding-low-latency`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#about-hyperthreading-for-low-latency-and-real-time-applications_cnf-understanding-low-latency`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#about-hyperthreading-for-low-latency-and-real-time-applications_cnf-understanding-low-latency`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#about-hyperthreading-for-low-latency-and-real-time-applications_cnf-understanding-low-latency`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#about-hyperthreading-for-low-latency-and-real-time-applications_cnf-understanding-low-latency`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#about-hyperthreading-for-low-latency-and-real-time-applications_cnf-understanding-low-latency`.

#### Scenario: 7.3.tsr.3_22_2_performance_profile_match_mcp loads
- WHEN `get_entry` is called with `7.3.tsr.3_22_2_performance_profile_match_mcp`
- THEN the title is `3.22.2. Performance Profile Match MCP`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_22_3_performance_profile_status
`load_kb()` SHALL contain `7.3.tsr.3_22_3_performance_profile_status` from `7_3_components.toml`. Title SHALL be `3.22.3. Performance Profile Status`.

description SHALL be:

Checks the status conditions of applied PerformanceProfiles. Degraded or
progressing profiles indicate nodes that have not successfully applied the
performance tuning configuration.

recommendation SHALL be:

Bring the profile to `Available=True` with no Degraded condition. If Degraded, read tuned logs before editing the profile — a profile change reboots the pool.

verification SHALL be:

1. Print profile conditions:
   `oc get performanceprofile -A -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .status.conditions[*]}{.type}={.status} reason={.reason}{"\n"}{end}{end}'`
2. Investigate degraded profiles in tuned logs:
   `oc logs -n openshift-cluster-node-tuning-operator ds/tuned --tail=50`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the PerformanceProfile pool

impact_detail SHALL be:

A profile change is applied through Machine Config, which drains and reboots nodes in that pool one at a time.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#cnf-understanding-low-latency`.

#### Scenario: 7.3.tsr.3_22_3_performance_profile_status loads
- WHEN `get_entry` is called with `7.3.tsr.3_22_3_performance_profile_status`
- THEN the title is `3.22.3. Performance Profile Status`
- AND `content_from` is empty


### Requirement: KB 7.3.tsr.3_22_4_performance_profile_configuration
`load_kb()` SHALL contain `7.3.tsr.3_22_4_performance_profile_configuration` from `7_3_components.toml`. Title SHALL be `3.22.4. Performance Profile Configuration`.

description SHALL be:

Reviews PerformanceProfile configuration details including CPU isolation,
hugepages, NUMA topology, and real-time kernel settings. Incorrect
configuration can degrade workload performance or waste resources.

recommendation SHALL be:

Match reserved versus isolated CPU, hugepages, NUMA policy, and the real-time kernel to the platform CPU layout. A patch here generates MachineConfig and reboots the targeted pool.

verification SHALL be:

1. Print CPU sets, hugepages, NUMA policy, and realTimeKernel:
   `oc get performanceprofile -A -o custom-columns=NAME:.metadata.name,RESERVED:.spec.cpu.reserved,ISOLATED:.spec.cpu.isolated,HUGEPAGES:.spec.hugepages,NUMA:.spec.numa.topologyPolicy,RT:.spec.realTimeKernel.enabled`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in targeted MachineConfigPool

impact_detail SHALL be:

PerformanceProfile changes generate new MachineConfig and TunedProfile resources that trigger a rolling node reboot in the targeted pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#cnf-understanding-low-latency`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#cnf-understanding-low-latency`.

#### Scenario: 7.3.tsr.3_22_4_performance_profile_configuration loads
- WHEN `get_entry` is called with `7.3.tsr.3_22_4_performance_profile_configuration`
- THEN the title is `3.22.4. Performance Profile Configuration`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_1_1_2_related_subscriptions
`load_kb()` SHALL contain `7.4.tsr.4_8_1_1_2_related_subscriptions` from `7_4_layered.toml`. Title SHALL be `TSR CNV related subscriptions`.

description SHALL be:

OpenShift Virtualization depends on related operator subscriptions in the virt namespace and in sibling namespaces (for example workload-availability). Missing or degraded subscriptions block CNV features and upgrades.

recommendation SHALL be:

Keep the kubevirt-hyperconverged Subscription at `AtLatestKnown` with installedCSV matching currentCSV. Treat absent workload-availability, NMState, or SR-IOV namespaces as optional integration components unless the virtualization design requires them. For a stalled required subscription, review and complete or approve its `InstallPlan`, then confirm the CSV reaches Succeeded.

verification SHALL be:

1. List the Virtualization operator subscription in openshift-cnv. Healthy when STATE is `AtLatestKnown` and INSTALLED matches CURRENT. If that namespace does not exist, the command prints **INFO** — Virtualization is not installed.
   `oc get subscription -n openshift-cnv -o custom-columns=NAME:.metadata.name,PACKAGE:.spec.name,CHANNEL:.spec.channel,STATE:.status.state,INSTALLED:.status.installedCSV,CURRENT:.status.currentCSV 2>&1 | awk '/not found/{print "INFO n/a-cnv"; n=1; next} NR==1{print "RESULT",$0; next} {r="FAIL"; if($1=="kubevirt-hyperconverged" && $4=="AtLatestKnown" && $5==$6) r="PASS"; print r,$0} END{if(!n && NR==1) print "FAIL missing-kubevirt-hyperconverged"}'`
2. Print the kubevirt-hyperconverged-operator CSV. Succeeded PHASE is healthy; any other phase is a failure.
   `oc get csv -n openshift-cnv 2>&1 | awk '/not found/{print "INFO n/a-cnv"; n=1; next} NR==1{print "RESULT",$0; next} $1 ~ /^kubevirt-hyperconverged-operator/ {r=($NF=="Succeeded"?"PASS":"FAIL"); print r,$0; found=1} END{if(!n && !found) print "FAIL missing-kubevirt-hyperconverged-operator"}'`
3. List optional related subscriptions in workload-availability, nmstate, and sriov namespaces. If a namespace does not exist, the command prints **INFO** and moves on.
   `oc get subscription,csv -n openshift-workload-availability 2>&1 | awk '/No resources found|not found|have a resource type/{print "INFO n/a-workload-availability"; n=1; next} {print} END{if(!n && NR==0) print "INFO n/a-workload-availability"}' && \
   oc get subscription,csv -n openshift-nmstate 2>&1 | awk '/No resources found|not found|have a resource type/{print "**INFO** n/a-nmstate"; `n=1`; next} {print} END{if(!n && NR==0) print "**INFO** n/a-nmstate"}' && \
   oc get subscription,csv -n openshift-sriov-network-operator 2>&1 | awk '/No resources found|not found|have a resource type/{print "**INFO** n/a-sriov"; `n=1`; next} {print} END{if(!n && NR==0) print "**INFO** n/a-sriov"}'`
4. If a required subscription failed, list `InstallPlan`s that are not Complete.
   `oc get installplan -n openshift-cnv -o custom-columns=NAME:.metadata.name,CSV:.spec.clusterServiceVersionNames,APPROVED:.spec.approved,PHASE:.status.phase | awk 'NR==1{print; next} $4!="Complete"{print; n++} END{if(n+0==0) print "PASS no-stuck-installplans"}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

openshift-cnv operator namespace

impact_detail SHALL be:

Approving `InstallPlan`s or reconciling CNV subscriptions rolls operator-managed pods but does not reboot cluster nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-subscribing-cli_installing-virt`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-subscribing-cli_installing-virt`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-subscribing-cli_installing-virt`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-subscribing-cli_installing-virt`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-subscribing-cli_installing-virt`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-subscribing-cli_installing-virt`.

#### Scenario: 7.4.tsr.4_8_1_1_2_related_subscriptions loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_1_1_2_related_subscriptions`
- THEN the title is `TSR CNV related subscriptions`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_1_3_4_node_disk
`load_kb()` SHALL contain `7.4.tsr.4_8_1_3_4_node_disk` from `7_4_layered.toml`. Title SHALL be `4.8.1.3.4 Default virtualization StorageClass`.

description SHALL be:

This finding is whether a default StorageClass for virtualization workloads exists (annotation storageclass.kubevirt.io/is-default-virt-class), not node root-disk fullness or kubelet DiskPressure. A cluster-wide default StorageClass is a different setting.

recommendation SHALL be:

Mark exactly one StorageClass with the virt-default annotation for VM disks, and keep a VolumeSnapshotClass whose DRIVER matches that provisioner. Annotate only after you confirm the provisioner. Empty snapshot classes mean snapshots are not in use. Missing virt-default is a problem when VMs need a default disk class.

verification SHALL be:

1. List each StorageClass provisioner and virt-default annotation.
   `oc get storageclass -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner,VIRTDEFAULT:.metadata.annotations.storageclass\.kubevirt\.io/is-default-virt-class`
2. Annotate the StorageClass that should back VM disks.
   `oc annotate storageclass <name> storageclass.kubevirt.io/is-default-virt-class=true`
3. Print VolumeSnapshotClass DRIVER values. If the CRD is missing or empty the command prints **INFO**. The DRIVER should match the virt-default PROVISIONER from step 1.
   `oc get volumesnapshotclass 2>&1 | awk '/No resources found|have a resource type/{print "INFO n/a-volumesnapshotclass"; n=1; next} {print} END{if(!n && NR==0) print "INFO n/a-volumesnapshotclass"}'`
No virt-default class when VMs need one is a failure. Empty snapshot classes are informational.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

StorageClass annotations for VM disks

impact_detail SHALL be:

Setting `storageclass.kubevirt.io/is-default-virt-class` changes which class new VM disks pick. It does not drain nodes or move existing PVCs.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-node-maintenance`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-node-maintenance`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-node-maintenance`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-node-maintenance`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-node-maintenance`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-node-maintenance`.

#### Scenario: 7.4.tsr.4_8_1_3_4_node_disk loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_1_3_4_node_disk`
- THEN the title is `4.8.1.3.4 Default virtualization StorageClass`
- AND `content_from` is empty


### Requirement: KB 7.4.cnv.live_migratable
`load_kb()` SHALL contain `7.4.cnv.live_migratable` from `7_4_layered.toml`. Title SHALL be `VM live-migratable status (engine)`.

description SHALL be:

This finding reads VirtualMachineInstance LiveMigratable conditions and VirtualMachine `evictionStrategy`. Live-migration network configuration is a separate finding.

recommendation SHALL be:

Ensure every VMI reports `LiveMigratable=True` so nodes can drain during maintenance without VM outage. False means a PDB, local disk, or selector constraint is blocking migration — read the reason before changing `evictionStrategy`. Do not add a migration NAD to fix this; it is a workload constraint.

verification SHALL be:

1. Print each VMI LiveMigratable condition with reason and message. An empty list means no VMIs exist. False needs review — the reason and message explain the constraint.
   `oc get vmi -A -o json | jq -r '["RESULT","NS","NAME","PHASE","LIVEMIG","REASON","MESSAGE"], (if (.items|length)==0 then ["INFO","-","-","-","-","-","n/a-vmi"] else .items[] | ([.status.conditions[]? | select(.type=="LiveMigratable")][0] // {}) as $c | [(if $c.status=="True" then "PASS" elif $c.status=="False" then "WARNING" else "INFO" end), .metadata.namespace, .metadata.name, (.status.phase // "-"), ($c.status // "-"), ($c.reason // "-"), ($c.message // "-")] end) | @tsv' | column -t -s $'\t'`
2. Print each VM `evictionStrategy`. LiveMigrate is the expected production value; other strategies are informational.
   `oc get vm -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,EVICTION:.spec.template.spec.evictionStrategy | awk 'NR==1{print "RESULT",$0; next} {e=$3; r="INFO"; if(e=="LiveMigrate") r="PASS"; print r,$0} END{if(NR==1) print "INFO n/a-vm"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

affected VMs

impact_detail SHALL be:

Making a VM live-migratable may require storage, networking, or eviction-policy changes and can require a VM reboot.

#### Scenario: 7.4.cnv.live_migratable loads
- WHEN `get_entry` is called with `7.4.cnv.live_migratable`
- THEN the title is `VM live-migratable status (engine)`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_1_5_1_1_cnv_operators_node_placement
`load_kb()` SHALL contain `7.4.tsr.4_8_1_5_1_1_cnv_operators_node_placement` from `7_4_layered.toml`. Title SHALL be `TSR CNV operators node placement`.

description SHALL be:

This check validates where OpenShift Virtualization infrastructure and VM workloads can run. It compares the HyperConverged resource's `spec.infra.nodePlacement` and `spec.workloads.nodePlacement` settings with the `virt-handler` DaemonSet placement and readiness, then verifies that intended VM nodes are eligible for virtualization. `virt-handler` is a node-level DaemonSet, so its Ready count should equal its Desired count on all nodes selected to host virtualization components; `virt-launcher` is instead created per running VM. Node-placement rules use exact label matching, and empty `nodePlacement` uses the platform default scheduling behavior.

recommendation SHALL be:

Align HyperConverged node-placement rules, node labels, taints/tolerations, and the `virt-handler` DaemonSet before changing node eligibility. Ensure every node intended to host VMs has `kubevirt.io/schedulable=true`, exposes the required hardware-virtualization CPU capability (`vmx` for Intel or `svm` for AMD), and has a running `virt-handler` pod. For a **WARNING** where `virt-handler` Ready does not equal Desired, identify the affected nodes and resolve the scheduling or runtime cause—such as a nonmatching selector, missing toleration, unsatisfied affinity rule, incompatible CPU virtualization support, resource pressure, or an unhealthy pod—rather than simply relabeling nodes. If placement is intentionally restricted, ensure the HyperConverged workload placement and `virt-handler` selector target the same node set.

verification SHALL be:

1. Confirm virt-handler DaemonSet READY equals DESIRED. If the DS does not exist, Virtualization is not installed.
   `oc get ds virt-handler -n openshift-cnv 2>&1 | awk '/not found/{print "INFO n/a-cnv"; next} NR==1{next} {print ($4==$2?"PASS":"FAIL"), "READY="$4, "DESIRED="$2, $1}'`
2. Print HyperConverged infra and workloads nodeSelector. A value of <none> means default placement on all nodes.
   `oc get hyperconverged kubevirt-hyperconverged -n openshift-cnv -o custom-columns=NAME:.metadata.name,INFRA_SEL:.spec.infra.nodePlacement.nodeSelector,WORKLOADS_SEL:.spec.workloads.nodePlacement.nodeSelector`
3. Print kubevirt.io/schedulable and CPU-feature labels (vmx for Intel, svm for AMD). Healthy when schedulable is true and at least one hardware-virt flag is present.
   `oc get nodes -L kubevirt.io/schedulable -L cpu-feature.node.kubevirt.io/svm -L cpu-feature.node.kubevirt.io/vmx | awk 'NR==1{print "RESULT",$0; next} {r="FAIL"; if($6=="true" && ($7=="true" || $8=="true")) r="PASS"; print r,$0}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

CNV infrastructure pods and VM-capable worker nodes

impact_detail SHALL be:

Changing schedulable labels or node placement reschedules CNV components and can require VM migration before draining or repurposing nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-specifying-nodes-for-vms_virt-node-placement-virt-handler`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-specifying-nodes-for-vms_virt-node-placement-virt-handler`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-specifying-nodes-for-vms_virt-node-placement-virt-handler`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-specifying-nodes-for-vms_virt-node-placement-virt-handler`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-specifying-nodes-for-vms_virt-node-placement-virt-handler`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-specifying-nodes-for-vms_virt-node-placement-virt-handler`.

#### Scenario: 7.4.tsr.4_8_1_5_1_1_cnv_operators_node_placement loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_1_5_1_1_cnv_operators_node_placement`
- THEN the title is `TSR CNV operators node placement`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_1_5_1_5_vm_run_strategy_and_availability
`load_kb()` SHALL contain `7.4.tsr.4_8_1_5_1_5_vm_run_strategy_and_availability` from `7_4_layered.toml`. Title SHALL be `TSR VM run strategy and availability`.

description SHALL be:

VM RunStrategy controls how VMs behave during node failures and maintenance.
`Always` ensures automatic restart on healthy nodes; `Manual` requires operator
intervention. Production VMs should use `Always` with live migration enabled.

recommendation SHALL be:

Set production VMs to RunStrategy Always with LiveMigrate eviction. Leave Manual only when the SLA requires operator-driven recovery. Empty VM list is n/a — do not fail the cluster for having no guests.

verification SHALL be:

1. List each VM runStrategy. Always is the expected production value; Manual or RerunOnFailure is a design decision, not automatic failure. An empty list means no VMs exist.
   `oc get vm -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,STRATEGY:.spec.runStrategy`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

virtual machine policy

impact_detail SHALL be:

Updating runStrategy or eviction policy changes future failover and maintenance behavior immediately, but it does not reboot nodes or stop running VMs by itself.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#run-strategies`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#run-strategies`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#run-strategies`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#run-strategies`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#run-strategies`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#run-strategies`.

#### Scenario: 7.4.tsr.4_8_1_5_1_5_vm_run_strategy_and_availability loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_1_5_1_5_vm_run_strategy_and_availability`
- THEN the title is `TSR VM run strategy and availability`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_2_1_1_3_live_migration_network_readiness
`load_kb()` SHALL contain `7.4.tsr.4_8_2_1_1_3_live_migration_network_readiness` from `7_4_layered.toml`. Title SHALL be `TSR live migration network readiness`.

description SHALL be:

This check evaluates which network the HyperConverged resource uses for live-migration traffic. An empty value uses the default pod network. A named network must exist as a NetworkAttachmentDefinition in openshift-cnv.

recommendation SHALL be:

Set HyperConverged live-migration network to a NAD that exists in openshift-cnv, or leave it empty to use the default pod network. Create the NAD or clear the pin if the named network is missing. Do not treat LiveMigratable False as this row; that is guest constraints.

verification SHALL be:

1. Print the HyperConverged live-migration network name. A value of <none> means the default pod network is in use. If the HyperConverged resource does not exist, Virtualization is not installed.
   `oc get hyperconverged kubevirt-hyperconverged -n openshift-cnv -o custom-columns=NAME:.metadata.name,NETWORK:.spec.liveMigrationConfig.network 2>&1 | awk '/not found/{print "INFO n/a-cnv"; next} NR==1{next} {n=$2; if(n=="<none>"||n=="") print "INFO NETWORK=<none>", $1; else print "NETWORK="n, $1}'`
2. List NADs in openshift-cnv. If step 1 named a network, that name must appear here; a missing NAD needs action.
   `oc get net-attach-def -n openshift-cnv`

impact SHALL be:

workload-shift

impact_scope SHALL be:

live-migration traffic path and virt-handler pods

impact_detail SHALL be:

Adding a dedicated migration network updates HyperConverged migration settings and restarts virt-handler pods; migration traffic then shifts off the primary cluster network.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-dedicated-network-live-migration`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-dedicated-network-live-migration`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-dedicated-network-live-migration`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-dedicated-network-live-migration`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-dedicated-network-live-migration`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-dedicated-network-live-migration`.

#### Scenario: 7.4.tsr.4_8_2_1_1_3_live_migration_network_readiness loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_2_1_1_3_live_migration_network_readiness`
- THEN the title is `TSR live migration network readiness`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_2_2_1_2_network_configuration
`load_kb()` SHALL contain `7.4.tsr.4_8_2_2_1_2_network_configuration` from `7_4_layered.toml`. Title SHALL be `TSR network configuration`.

description SHALL be:

This check verifies that the node network configuration required for virtual machine connectivity is properly set up. It looks for NodeNetworkConfigurationPolicy (NNCP) and NodeNetworkConnectionEnactment (NNCE) resources. Missing or failed network policies mean VMs may not be able to connect to external networks or other VMs.

recommendation SHALL be:

Validate that the host networking required by VM bridges, VLANs, and secondary networks is present and healthy on every node eligible to run those VMs. Where the configuration is managed through the Kubernetes NMState Operator, confirm that the applicable NodeNetworkConfigurationPolicy resources and their per-node NodeNetworkConfigurationEnactment results are in the SuccessfullyConfigured state; investigate and remediate any failed enactments before scheduling or attaching additional VMs to the affected network. The absence of NNCPs or NNCEs is not, by itself, a finding: the required host networking may have been configured during installation in install-config.yaml, provisioned by another supported mechanism, or may not be required when VMs use only the default overlay network.

verification SHALL be:

1. List NodeNetworkConfigurationPolicy and NodeNetworkConfigurationEnactment resources.
   `oc get nncp` and `oc get nnce`
2. If NNCPs exist but show errors, inspect detailed enactment status.
   `oc get nnce -o wide`
3. List all NetworkAttachmentDefinitions for VM network connectivity.
   `oc get net-attach-def -A`
If no NNCP or NNCE exists and the cluster uses only the overlay network, the absence is expected. A failed enactment needs investigation.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

targeted worker-node networking and attached VM interfaces

impact_detail SHALL be:

Bridge, SR-IOV, or other host-network changes can interrupt node and VM connectivity while the node networking is reconfigured.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`.

A summary pattern containing `no NNCE found` SHALL produce `No NodeNetworkConfigurationEnactment was found for VM node networking.`.

#### Scenario: 7.4.tsr.4_8_2_2_1_2_network_configuration loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_2_2_1_2_network_configuration`
- THEN the title is `TSR network configuration`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_3_1_1_storage_profiles
`load_kb()` SHALL contain `7.4.tsr.4_8_3_1_1_storage_profiles` from `7_4_layered.toml`. Title SHALL be `TSR storage profiles`.

description SHALL be:

This check validates CDI StorageProfile defaults for each StorageClass used by OpenShift Virtualization. It evaluates the configured clone strategy—`snapshot`, `csi-clone`, or host-assisted `copy`—and the default PVC properties in `claimPropertySets`, including access modes and volume mode. When the StorageProfile.spec fields are empty, CDI derives the effective values in the profile status from the StorageClass and CSI driver capabilities. `copy` cloning transfers data between source and target pods and is the least efficient method. `snapshot` cloning uses a CSI VolumeSnapshotClass, while `csi-clone` uses the CSI driver's native volume-clone API.

recommendation SHALL be:

Prefer `snapshot` or `csi-clone` for StorageClasses that support the corresponding CSI capability and are used for VM disks, templates, or frequent DataVolume clones. These methods avoid host-assisted data transfer and generally reduce clone time and cluster network or node-resource consumption. Keep `copy` only where the CSI driver does not support snapshots or CSI cloning, or where the required VolumeSnapshotClass is unavailable or does not match the StorageClass provisioner. Do not force a clone strategy solely to clear this warning: an unsupported `snapshot` or `csi-clone` configuration can cause DataVolume imports and VM cloning operations to fail.

verification SHALL be:

1. Print StorageProfile provisioner, effective clone strategy, and snapshotClass. A strategy of snapshot or csi-clone is healthy; copy means host-assisted cloning. If the CRD is missing or empty, the command prints **INFO**.
   `oc get storageprofile -o custom-columns=NAME:.metadata.name,PROVISIONER:.status.provisioner,CLONE:.status.cloneStrategy,SPEC_CLONE:.spec.cloneStrategy,SNAPCLASS:.spec.snapshotClass 2>&1 | awk '/have a resource type|No resources found/{print "INFO n/a-storageprofile"; n=1; next} NR==1{print "RESULT",$0; next} {c=$3; r="INFO"; if(c=="copy") r="WARNING"; else if(c=="csi-clone"||c=="snapshot") r="PASS"; print r,$0} END{if(!n && NR==0) print "INFO n/a-storageprofile"}'`
2. Print claimPropertySets accessModes and volumeMode per StorageProfile.
   `oc get storageprofile -o json | jq -r '["NAME","ACCESS","VOLMODE"], (.items[] as $sp | ($sp.status.claimPropertySets // [{}])[] as $claim | [$sp.metadata.name, (($claim.accessModes // []) | join(",") | if .=="" then "-" else . end), ($claim.volumeMode // "-")]) | @tsv' | column -t -s $'\t'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

new DataVolumes and VM disk defaults

impact_detail SHALL be:

StorageProfile changes affect future imports, clones, and PVC defaults; existing volumes and running VMs continue unchanged.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-customizing-storage-profile_virt-configuring-storage-profile`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-customizing-storage-profile_virt-configuring-storage-profile`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-customizing-storage-profile_virt-configuring-storage-profile`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-customizing-storage-profile_virt-configuring-storage-profile`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-customizing-storage-profile_virt-configuring-storage-profile`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-customizing-storage-profile_virt-configuring-storage-profile`.

#### Scenario: 7.4.tsr.4_8_3_1_1_storage_profiles loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_3_1_1_storage_profiles`
- THEN the title is `TSR storage profiles`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_3_2_1_nmstate_operator
`load_kb()` SHALL contain `7.4.tsr.4_8_3_2_1_nmstate_operator` from `7_4_layered.toml`. Title SHALL be `TSR NMState operator`.

description SHALL be:

This check evaluates the NMState operator used for NodeNetworkConfigurationPolicy. Failures include operator missing, CSV not current, or failed enactments.

recommendation SHALL be:

Confirm that the Kubernetes NMState Operator CSV in `openshift-nmstate` is **Succeeded** and current before modifying or reapplying any NodeNetworkConfigurationPolicy (NNCP). If the NMState namespace is absent and no NNCPs are in use, treat the result as not applicable.

verification SHALL be:

1. List the NMState operator CSV. If the namespace does not exist, NMState is not installed. A PHASE other than Succeeded is a failure.
   `oc get csv -n openshift-nmstate`
2. List NNCP and NNCE resources to detect failed enactments.
   `oc get nncp,nnce`
Missing namespace is informational. A failed NNCE is a failure.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

nodes targeted by NodeNetworkConfigurationPolicy

impact_detail SHALL be:

Applying or correcting NNCPs can briefly disrupt host networking; use controlled rollout settings such as `maxUnavailable` and validate rollback behavior.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/kubernetes_nmstate/index#k8s-nmstate-updating-node-network-config`.

#### Scenario: 7.4.tsr.4_8_3_2_1_nmstate_operator loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_3_2_1_nmstate_operator`
- THEN the title is `TSR NMState operator`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_3_2_2_sr_iov_operator
`load_kb()` SHALL contain `7.4.tsr.4_8_3_2_2_sr_iov_operator` from `7_4_layered.toml`. Title SHALL be `TSR SR-IOV operator`.

description SHALL be:

This check verifies whether the SR-IOV Network Operator is installed and available. The operator manages SR-IOV-capable NICs by configuring Physical Functions (PFs), creating Virtual Functions (VFs), and applying `SriovNetworkNodePolicy` resources to selected nodes. If the `openshift-sriov-network-operator` namespace or its `ClusterServiceVersion` (CSV) is missing, SR-IOV is not installed; this is an absence of an optional capability, not necessarily a configuration failure.

recommendation SHALL be:

Treat a missing SR-IOV namespace or CSV as not applicable unless the cluster design requires VFs for workloads, low-latency networking, or VM passthrough. If SR-IOV is required, install the SR-IOV Network Operator through OperatorHub or a supported Subscription, confirm its CSV reaches **Succeeded**, and create `SriovNetworkNodePolicy` resources that match the target nodes and supported NIC PFs. Do not use SR-IOV-related resources found in unrelated namespaces as evidence that the operator is installed. Validate installation from the operator namespace, then verify the policy status, discovered interfaces, allocated VFs, and the NetworkAttachmentDefinitions consumed by the intended pods or virtual machines.

verification SHALL be:

1. Search for an SR-IOV namespace and CSV. If none is found, SR-IOV is not installed — treat as informational unless the design requires it.
   `oc get csv,ns | grep -i sriov`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

SR-IOV-capable worker nodes and attached VMs/pods

impact_detail SHALL be:

Updating SR-IOV policies reprovisions virtual functions on the NIC and can interrupt workloads attached to those interfaces until reconciliation completes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/hardware_networks/index#configuring-sriov-network-devices`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/hardware_networks/index#configuring-sriov-network-devices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/hardware_networks/index#configuring-sriov-network-devices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/hardware_networks/index#configuring-sriov-network-devices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/hardware_networks/index#configuring-sriov-network-devices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/hardware_networks/index#configuring-sriov-network-devices`.

#### Scenario: 7.4.tsr.4_8_3_2_2_sr_iov_operator loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_3_2_2_sr_iov_operator`
- THEN the title is `TSR SR-IOV operator`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_3_2_3_linux_bridge_network
`load_kb()` SHALL contain `7.4.tsr.4_8_3_2_3_linux_bridge_network` from `7_4_layered.toml`. Title SHALL be `TSR Linux bridge network`.

description SHALL be:

This check inventories Linux-bridge VM network attachments. A Linux-bridge attachment is represented by a NetworkAttachmentDefinition (NAD) using the `cnv-bridge` or `bridge` CNI type, with a bridge name and, optionally, VLAN configuration. The referenced host bridge must exist on every node that may run a VM using that NAD. An NMState NodeNetworkConfigurationPolicy (NNCP) and its NodeNetworkConfigurationEnactment (NNCE) provide evidence that the bridge was configured and successfully applied through NMState. However, they are not required when the bridge was created during cluster installation or is otherwise managed outside NMState.

recommendation SHALL be:

For every required Linux-bridge VM network, ensure the `cnv-bridge` or `bridge` NAD references a host bridge that exists and is operational on all eligible VM nodes. Confirm that its bridge name, physical uplink or bond, VLAN design, node placement, and VM scheduling constraints are consistent. Use an NNCP as the preferred, declarative day-2 method to create or maintain the bridge, and require a successful NNCE when NMState manages it. If the bridge was configured through `install-config.yaml` during installation or another approved host-configuration method, treat the absence of an NNCP as informational and not a failure.

verification SHALL be:

1. List NNCE resources. If the CRD is missing or empty, host bridges are not enacted here.
   `oc get nnce 2>&1 | awk '/have a resource type|No resources found/{print "INFO n/a-nnce"; n=1; next} {print} END{if(!n && NR==0) print "INFO n/a-nnce"}'`
2. Print each NAD TYPE, BRIDGE, and VLAN. A type of cnv-bridge or bridge is healthy; other types are informational. An empty list means no NADs exist.
   `oc get net-attach-def -A -o json | jq -r '.items[] | (.spec.config|fromjson) as $c | [.metadata.namespace, .metadata.name, $c.type, ($c.bridge // "-"), ($c.vlan // "-")] | @tsv' | awk 'BEGIN{print "RESULT","NS","NAME","TYPE","BRIDGE","VLAN"} {r="INFO"; if($3=="cnv-bridge"||$3=="bridge") r="PASS"; print r,$0} END{if(NR==0) print "INFO n/a-nad"}' | column -t`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

targeted worker nodes and bridge-attached VM interfaces

impact_detail SHALL be:

Linux bridge changes are host-network reconfiguration events and can temporarily drop connectivity for affected nodes or VMs during application.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-connecting-vm-to-linux-bridge`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-connecting-vm-to-linux-bridge`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-connecting-vm-to-linux-bridge`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-connecting-vm-to-linux-bridge`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-connecting-vm-to-linux-bridge`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-connecting-vm-to-linux-bridge`.

#### Scenario: 7.4.tsr.4_8_3_2_3_linux_bridge_network loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_3_2_3_linux_bridge_network`
- THEN the title is `TSR Linux bridge network`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_4_2_windows_bsod_risk_posture
`load_kb()` SHALL contain `7.4.tsr.4_8_4_2_windows_bsod_risk_posture` from `7_4_layered.toml`. Title SHALL be `TSR Windows BSOD risk posture`.

description SHALL be:

Windows VMIs should expose a hypervisor watchdog or equivalent liveness so a guest hang or BSOD can be detected and recovered. Missing watchdog or liveness configuration leaves failed Windows guests undetected.

recommendation SHALL be:

Enable a hypervisor watchdog or guest-agent liveness on every Windows VMI, with a restart policy that matches the recovery SLA. Put it on templates so new VMs inherit it. Do not chase individual guests first.

verification SHALL be:

1. Print desired watchdog and liveness on each VirtualMachine spec. `WINDOWS=yes` when the VM name, labels, or annotations mention windows. A Windows row with both WATCHDOG and LIVENESS unset needs review. An empty list means no VMs exist:
   `oc get vm -A -o json | jq -r '.items[] | [.metadata.namespace, .metadata.name, (if (((.metadata.name // "") + " " + ((.metadata.labels // {})|tostring) + " " + ((.metadata.annotations // {})|tostring) + " " + ((.spec.template.metadata.labels // {})|tostring) + " " + ((.spec.template.metadata.annotations // {})|tostring)) | test("windows"; "i")) then "yes" else "no" end), ((.spec.template.spec.domain.devices.watchdog // {}) | if length==0 then "-" else (keys[0] // "set") end), (if .spec.template.spec.livenessProbe then "set" else "-" end)] | @tsv' | awk -F'\t' 'BEGIN{print "RESULT","NS","NAME","WINDOWS","WATCHDOG","LIVENESS"} {r="INFO"; if($3=="yes"){r="PASS"; if($4=="-" && $5=="-") r="WARNING"} print r,$0} END{if(NR==0) print "INFO n/a-vm"}'`
2. Print the same fields on running VirtualMachineInstances, including guest OS when reported. `WINDOWS=yes` when the VMI name, labels, annotations, or guestOSInfo mention windows. A Windows row with both WATCHDOG and LIVENESS unset needs review. An empty list means no VMIs exist:
   `oc get vmi -A -o json | jq -r '.items[] | [.metadata.namespace, .metadata.name, (if (((.metadata.name // "") + " " + ((.metadata.labels // {})|tostring) + " " + ((.metadata.annotations // {})|tostring) + " " + ((.status.guestOSInfo.name // ""))) | test("windows"; "i")) then "yes" else "no" end), ((.spec.domain.devices.watchdog // {}) | if length==0 then "-" else (keys[0] // "set") end), (if .spec.livenessProbe then "set" else "-" end), (.status.guestOSInfo.name // "-")] | @tsv' | awk -F'\t' 'BEGIN{print "RESULT","NS","NAME","WINDOWS","WATCHDOG","LIVENESS","GUESTOS"} {r="INFO"; if($3=="yes"){r="PASS"; if($4=="-" && $5=="-") r="WARNING"} print r,$0} END{if(NR==0) print "INFO n/a-vmi"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

Windows virtual machines

impact_detail SHALL be:

Enabling a watchdog or changing restart policy can restart individual Windows VMs; it does not reboot hypervisor nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index`.

#### Scenario: 7.4.tsr.4_8_4_2_windows_bsod_risk_posture loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_4_2_windows_bsod_risk_posture`
- THEN the title is `TSR Windows BSOD risk posture`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_4_3_windows_hyper_v_enlightenments
`load_kb()` SHALL contain `7.4.tsr.4_8_4_3_windows_hyper_v_enlightenments` from `7_4_layered.toml`. Title SHALL be `TSR Windows Hyper-V enlightenments`.

description SHALL be:

Hyper-V enlightenments improve Windows guest timekeeping, spinlocks, and I/O on KVM. Windows VMIs without those features run, but with higher overhead and weaker guest integration.

recommendation SHALL be:

Enable Hyper-V enlightenments on Windows templates, then restart or live-migrate the VMI. An empty HYPERV column means they are off — the VM still runs, just heavier. Do not leave this as a per-VM one-off.

verification SHALL be:

1. Print each VMI Hyper-V feature flags. An empty list means no VMIs exist. A <none> or empty HYPERV column on a Windows VMI is a warning.
   `oc get vmi -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,HYPERV:.spec.domain.features.hyperv`

impact SHALL be:

workload-shift

impact_scope SHALL be:

Windows virtual machines

impact_detail SHALL be:

Applying enlightenments typically requires a VM reboot or live migration, not a cluster-node reboot.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index`.

#### Scenario: 7.4.tsr.4_8_4_3_windows_hyper_v_enlightenments loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_4_3_windows_hyper_v_enlightenments`
- THEN the title is `TSR Windows Hyper-V enlightenments`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_4_5_host_kernel_bsod_indicators
`load_kb()` SHALL contain `7.4.tsr.4_8_4_5_host_kernel_bsod_indicators` from `7_4_layered.toml`. Title SHALL be `TSR host kernel crash indicators`.

description SHALL be:

Kernel panics or BSOD-equivalent events on nodes indicate hardware failures,
driver issues, or critical kernel bugs. Affected nodes are unreliable and may
cause VM disruption without warning.

recommendation SHALL be:

Immediately cordon any VM host showing kernel panics, oopses, or `BUG` events to prevent new workload placement, then safely migrate or recover affected VMs as appropriate. Review BMC/iDRAC/iLO hardware logs, node journals, and `NodeNotReady` or reboot events before applying kernel, driver, or firmware remediation. Keep the node out of VM scheduling until the root cause is resolved and the host remains stable through validation. A clean journal with no related reboot or `NodeNotReady` events indicates no current evidence of this condition.

verification SHALL be:

1. Search node journals for kernel panic, oops, or BUG messages. Empty output is healthy.
   `oc adm node-logs <node> --path=journal | grep -iE 'panic|oops|BUG:'`
2. List `NodeNotReady` events that may indicate unexpected reboots. Correlate any results with hits from step 1.
   `oc get events -A --field-selector reason=NodeNotReady`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

affected VM-hosting nodes

impact_detail SHALL be:

Kernel or hardware remediation commonly requires cordon, drain, reboot, or replacement of the node, forcing VM migration or downtime if migration is unavailable.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-node-maintenance`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-node-maintenance`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-node-maintenance`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-node-maintenance`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-node-maintenance`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-node-maintenance`.

#### Scenario: 7.4.tsr.4_8_4_5_host_kernel_bsod_indicators loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_4_5_host_kernel_bsod_indicators`
- THEN the title is `TSR host kernel crash indicators`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_4_6_nfs_client_mount_posture
`load_kb()` SHALL contain `7.4.tsr.4_8_4_6_nfs_client_mount_posture` from `7_4_layered.toml`. Title SHALL be `TSR NFS client mount posture`.

description SHALL be:

This check reviews effective NFS client mount options on OpenShift nodes for NFS storage that backs VM disks. It identifies mounts using default or non-optimized settings, with particular attention to the `nconnect` option. `nconnect` allows a Linux NFS client to establish multiple TCP connections to the same NFS endpoint rather than the traditional single connection, which can increase I/O concurrency and throughput for a single client. The absence of `nconnect` is a performance optimization finding, not proof that the NFS export, StorageClass, CSI driver, or VM disk is unhealthy.

recommendation SHALL be:

For NFS StorageClasses used for performance-sensitive VM disks, validate `nconnect` with the storage vendor and benchmark a representative workload before adopting it. Where supported and beneficial, configure a consistent tested value (commonly `nconnect=4`, `8`, or `16`) through the supported CSI driver, NFS provisioner, or node configuration mechanism rather than by manually changing live mounts. Start with a conservative value and measure latency, throughput, IOPS, NFS retransmissions, and storage-controller load before scaling it out. The first mount from a node to a given NFS server endpoint establishes the `nconnect` value that subsequent mounts to that endpoint use. Inconsistent mount options can therefore produce unexpected results. Do not remount NFS volumes used by running VM disks simply to add `nconnect`, and do not treat a missing option as an outage. Retain the existing configuration if testing shows no improvement, introduces server contention, or is unsupported by the CSI driver or storage vendor.

verification SHALL be:

1. Print live NFS mounts on a node in the host mount namespace. Mounts with nconnect in OPTIONS are healthy; those without need review. An empty list means no NFS mounts exist on this node.
   `oc debug node/<name> --quiet -- nsenter -t 1 -m -- findmnt -t nfs,nfs4 -o SOURCE,TARGET,OPTIONS | awk 'NR==1{print "RESULT",$0; next} {r="WARNING"; if($0 ~ /nconnect/) r="PASS"; print r,$0} END{if(NR<=1) print "INFO n/a-nfs"}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

nodes and workloads using NFS-backed VM storage

impact_detail SHALL be:

Correcting NFS mount posture can require remounting or restarting NFS-backed workloads and is safest during a planned window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#storage-persistent-storage-pv-pvmountoptions_understanding-persistent-storage`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#storage-persistent-storage-pv-pvmountoptions_understanding-persistent-storage`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#storage-persistent-storage-pv-pvmountoptions_understanding-persistent-storage`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#storage-persistent-storage-pv-pvmountoptions_understanding-persistent-storage`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#storage-persistent-storage-pv-pvmountoptions_understanding-persistent-storage`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#storage-persistent-storage-pv-pvmountoptions_understanding-persistent-storage`.

#### Scenario: 7.4.tsr.4_8_4_6_nfs_client_mount_posture loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_4_6_nfs_client_mount_posture`
- THEN the title is `TSR NFS client mount posture`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_4_7_nfs_client_sysctl_posture
`load_kb()` SHALL contain `7.4.tsr.4_8_4_7_nfs_client_sysctl_posture` from `7_4_layered.toml`. Title SHALL be `TSR NFS client sysctl posture`.

description SHALL be:

This check evaluates NFS client concurrency limits on OpenShift nodes that mount NFS-backed storage. It reviews the RPC slot-table and NFSv4 session-slot parameters (primarily `sunrpc.tcp_max_slot_table_entries` and `nfs.max_session_slots`) which limit the number of in-flight NFS operations a node can issue. Low effective limits can constrain throughput and increase queueing for high-IOPS VM disks, even when the network and NFS server have available capacity.

recommendation SHALL be:

First capture the live values, NFS protocol versions, mount options, and workload behavior on representative VM worker nodes. For an NFSv3 workload, tune the applicable `sunrpc` TCP slot-table settings only to the storage vendor's documented per-connection limit. For NFSv4.1, use `nfs.max_session_slots` no higher than the NFS server supports. Apply approved sysctl tuning through the Node Tuning Operator and a targeted Tuned profile where possible, so the setting is declarative and limited to the worker nodes mounting the relevant NFS storage. Because these limits may affect only mounts established after the setting is applied, schedule changes with a maintenance window, controlled VM migration, or restart/remount plan.

verification SHALL be:

1. Read the sunrpc.tcp_max_slot_table_entries sysctl on a node. Command failure or no NFS nodes is informational. A value below 128 (or the vendor recommendation) is a warning.
   `oc debug node/<name> -- chroot /host sysctl sunrpc.tcp_max_slot_table_entries`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

nodes using NFS-backed virtualization workloads

impact_detail SHALL be:

Tuned profiles can apply live, but MachineConfig-based sysctl changes drain and reboot nodes; treat this as planned node-by-node remediation.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#custom-tuning-specification_node-tuning-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#custom-tuning-specification_node-tuning-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#custom-tuning-specification_node-tuning-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#custom-tuning-specification_node-tuning-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#custom-tuning-specification_node-tuning-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#custom-tuning-specification_node-tuning-operator`.

#### Scenario: 7.4.tsr.4_8_4_7_nfs_client_sysctl_posture loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_4_7_nfs_client_sysctl_posture`
- THEN the title is `TSR NFS client sysctl posture`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_1_4_1_cpu_physical_resource_overhead_requirements
`load_kb()` SHALL contain `7.4.tsr.4_8_1_4_1_cpu_physical_resource_overhead_requirements` from `7_4_layered.toml`. Title SHALL be `4.8.1.4.1. CPU Physical Resource Overhead Requirements`.

description SHALL be:

This check collects node CPU overhead versus allocatable CPU, HyperConverged `vmiCPUAllocationRatio`, optional dedicated CPU placement, and Node Tuning Operator health. A WARNING on CSV not fully healthy is an operator-health finding. Missing PerformanceProfile is informational. Nodes that already report overhead are not the defect by themselves.

recommendation SHALL be:

If node CPU overhead collection passed, do not change `vmiCPUAllocationRatio` or add a PerformanceProfile only to clear this check. Investigate the Node Tuning Operator CSV that is not Succeeded (or not fully healthy): CSV phase, operator pod, and InstallPlan. Dedicated CPU and PerformanceProfile stay optional unless the design requires low-latency VMs.

verification SHALL be:

1. Print Node Tuning Operator CSVs. Succeeded is healthy.
   `oc get csv -n openshift-cluster-node-tuning-operator`
2. Print HyperConverged `vmiCPUAllocationRatio`. A set ratio is expected when Virtualization is installed.
   `oc get hyperconverged kubevirt-hyperconverged -n openshift-cnv -o jsonpath='{.spec.vmiCPUAllocationRatio}{"\n"}'`
3. If Virtualization is not installed, the hyperconverged command prints not found — INFO, skip.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

openshift-cluster-node-tuning-operator

impact_detail SHALL be:

Repairing the CSV rolls NTO operator pods; it does not by itself apply a PerformanceProfile.

Links SHALL be `default` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.18` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.19` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.20` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.21` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.22` -> `https://access.redhat.com/support/policy/updates/openshift_operators`.

#### Scenario: 7.4.tsr.4_8_1_4_1_cpu_physical_resource_overhead_requirements loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_1_4_1_cpu_physical_resource_overhead_requirements`
- THEN the title is `4.8.1.4.1. CPU Physical Resource Overhead Requirements`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_4_9_smbios_baseboard_serial_posture
`load_kb()` SHALL contain `7.4.tsr.4_8_4_9_smbios_baseboard_serial_posture` from `7_4_layered.toml`. Title SHALL be `4.8.4.9. SMBIOS Baseboard Serial Posture`.

description SHALL be:

KubeVirt does not copy the worker node's SMBIOS baseboard serial into the guest by default. Some Windows activation and ISV license tools read firmware serial and UUID. Missing `spec.template.spec.domain.firmware.serial` and `uuid` on a VirtualMachine is a guest-identity gap only when those tools require it.

recommendation SHALL be:

Set `spec.template.spec.domain.firmware.serial` and `spec.template.spec.domain.firmware.uuid` on a Windows VirtualMachine only when licensing or activation needs a stable firmware identity. Do not mass-edit every VM to clear the check. Do not expect the hypervisor host baseboard serial to appear in the guest (KCS 7144584). If no Windows VMs exist, this check is informational.

verification SHALL be:

1. List VirtualMachines and firmware serial and uuid. Empty VM list is INFO.
   `oc get vm -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,SERIAL:.spec.template.spec.domain.firmware.serial,UUID:.spec.template.spec.domain.firmware.uuid`
2. If a licensing tool still fails after serial/uuid are set, check the guest SMBIOS from inside the VM; host `dmidecode` on the worker is not the guest identity.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

selected VirtualMachine firmware fields

impact_detail SHALL be:

Changing firmware serial or uuid can require a VM reboot for the guest to see the new identity.

Links SHALL be `default` -> `https://access.redhat.com/solutions/7144584`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index`.

#### Scenario: 7.4.tsr.4_8_4_9_smbios_baseboard_serial_posture loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_4_9_smbios_baseboard_serial_posture`
- THEN the title is `4.8.4.9. SMBIOS Baseboard Serial Posture`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_5_1_1_quota_and_resources
`load_kb()` SHALL contain `7.4.tsr.4_8_5_1_1_quota_and_resources` from `7_4_layered.toml`. Title SHALL be `TSR CNV quota and resources`.

description SHALL be:

ResourceQuotas and LimitRanges in namespaces running VMs must account for
virt-launcher pod overhead. Insufficient quotas prevent VM starts and live
migrations.

recommendation SHALL be:

Size VM-namespace quotas for virt-launcher overhead (about 1 CPU per vCPU plus memory) and at least 2× the largest VM during migration. Raise quota before the next drain if used is near hard. Missing ResourceQuota means there is no cap, not that VMs are healthy.

verification SHALL be:

1. List ResourceQuota in the target VM namespace. Missing quota means there is no cap (informational). Used near hard limits is a warning for new VM starts or migrations.
   `oc get resourcequota -n <ns>`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

VM namespaces and admission control

impact_detail SHALL be:

Quota changes take effect immediately for new VM starts or migrations, but they do not restart nodes or stop already running VMs.

priority_hint SHALL be:

P3

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index`.

#### Scenario: 7.4.tsr.4_8_5_1_1_quota_and_resources loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_5_1_1_quota_and_resources`
- THEN the title is `TSR CNV quota and resources`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_5_2_1_active_alerts
`load_kb()` SHALL contain `7.4.tsr.4_8_5_2_1_active_alerts` from `7_4_layered.toml`. Title SHALL be `TSR CNV active alerts`.

description SHALL be:

This check reports firing OpenShift Virtualization alerts from Prometheus, including alerts such as `VMCannotBeEvicted`. These alerts identify current operational conditions that can affect VM availability, node maintenance, live migration, or the health of virtualization components. `VMCannotBeEvicted` fires when a VM is configured with `evictionStrategy: LiveMigrate` but its active VMI is not migratable. Common causes include non-migratable storage, restrictive placement or affinity rules, insufficient target-node capacity, or disruption constraints such as a PodDisruptionBudget.

recommendation SHALL be:

Investigate and resolve every firing OpenShift Virtualization alert according to its alert name, labels, and runbook. An empty Prometheus result is healthy: it means no matching alert is currently firing. For VMs that must remain available during node drains, upgrades, or maintenance, retain `evictionStrategy: LiveMigrate` and correct the condition preventing migration. Confirm that the VM uses migratable storage (typically shared RWX storage), has an eligible target node, and is not constrained. If a VM is intentionally non-migratable, set an eviction behavior consistent with its approved maintenance and recovery plan, such as shutdown, rather than leaving it configured for live migration that cannot occur.

verification SHALL be:

1. Query Prometheus for KubeVirt and VMCannot alerts (prints `state`, `alertname`, `severity`). Empty output means none are firing.
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname | test("KubeVirt|kubevirt|VMCannot"; "i")) | {state, alertname: .labels.alertname, severity: .labels.severity}'`
2. If `VMCannotBeEvicted` is firing, inspect PodDisruptionBudgets for the affected VMI.
   `oc get pdb -A`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

virtual machines named in firing alerts

impact_detail SHALL be:

Investigating alerts does not restart nodes; making a VM migratable may migrate that VM.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-runbooks`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-runbooks`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-runbooks`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-runbooks`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-runbooks`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-runbooks`.

#### Scenario: 7.4.tsr.4_8_5_2_1_active_alerts loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_5_2_1_active_alerts`
- THEN the title is `TSR CNV active alerts`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_5_2_3_cnv_vmi_readiness_prometheus
`load_kb()` SHALL contain `7.4.tsr.4_8_5_2_3_cnv_vmi_readiness_prometheus` from `7_4_layered.toml`. Title SHALL be `TSR CNV VMI readiness metrics`.

description SHALL be:

This check evaluates VirtualMachineInstance phase from Prometheus, both as a count by phase and as each guest by name. It is not an inventory of running virtual machines. Pending, Scheduling, Failed, or Unknown with a count above zero needs review; an empty result means no VirtualMachineInstance exists.

recommendation SHALL be:

Investigate each VirtualMachineInstance that is Pending, Scheduling, Failed, or Unknown and fix the scheduling, storage, or virt-launcher problem keeping that guest from Running. Running is the expected phase for active guests. No VirtualMachineInstance in Prometheus is informational when the cluster has no guests.

verification SHALL be:

1. Query kubevirt_vmi_phase_count from Prometheus. Phases Pending, Scheduling, Failed, or Unknown with a count above zero need review. An empty result means no VMIs exist.
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=kubevirt_vmi_phase_count' | jq -r '.data.result[] | [.metric.phase, .value[1]] | @tsv' | awk '{r="INFO"; if($1 ~ /Pending|Scheduling|Failed|Unknown/ && $2+0>0) r="WARNING"; print r, "PHASE="$1, "COUNT="$2} END{if(NR==0) print "INFO n/a-vmi"}'`
2. Query kubevirt_vmi_info to list each VMI by phase. Same warning phases apply. An empty result means no VMIs exist.
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=kubevirt_vmi_info' | jq -r '.data.result[] | [.metric.namespace, .metric.name, .metric.phase] | @tsv' | awk '{r="INFO"; if($3 ~ /Pending|Scheduling|Failed|Unknown/) r="WARNING"; print r, "NS="$1, "NAME="$2, "PHASE="$3} END{if(NR==0) print "INFO n/a-vmi"}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

virtual machines that are not ready

impact_detail SHALL be:

Investigating VMI readiness does not reboot nodes; fixing eviction or provisioning issues can migrate or restart individual VMs.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-querying-metrics_virt-prometheus-queries`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-querying-metrics_virt-prometheus-queries`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-querying-metrics_virt-prometheus-queries`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-querying-metrics_virt-prometheus-queries`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-querying-metrics_virt-prometheus-queries`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-querying-metrics_virt-prometheus-queries`.

#### Scenario: 7.4.tsr.4_8_5_2_3_cnv_vmi_readiness_prometheus loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_5_2_3_cnv_vmi_readiness_prometheus`
- THEN the title is `TSR CNV VMI readiness metrics`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_5_3_1_oadp_operator
`load_kb()` SHALL contain `7.4.tsr.4_8_5_3_1_oadp_operator` from `7_4_layered.toml`. Title SHALL be `TSR OADP operator`.

description SHALL be:

This check evaluates OADP / backup operator posture. Evidence may show a healthy OLM CSV in `openshift-adp`, or no CSV, OperatorGroup, or Subscription because the stack was installed outside OLM (Helm or manual).

recommendation SHALL be:

Verify that the cluster's intended backup solution is deployed, healthy, and capable of protecting the workloads it is responsible for. If OADP is the selected platform, confirm its health using the installation method in use: an OLM-managed deployment should have a Succeeded OADP CSV, while Helm- or manually deployed Velero/OADP should have an available DataProtectionApplication and functional BackupStorageLocation in the namespace where it is installed, which might not be openshift-adp. Do not treat missing OADP CSV, Subscription, or OperatorGroup resources as a failure when OADP is not used, is installed outside OLM, or another supported backup product fulfills the cluster backup requirement.

verification SHALL be:

1. Search for OADP or Velero OLM resources (CSV, Subscription, OperatorGroup). If none are found, record the result as informational unless the documented backup design requires OADP.
   `oc get csv,subscription,operatorgroup -A | grep -i -E 'oadp|velero|adp'`
For an OLM-managed deployment, the OADP CSV must be Succeeded; any other phase is a failure. A DataProtectionApplication or BackupStorageLocation that is not Available is also a failure when OADP is the designated backup platform.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

openshift-adp backup and restore components

impact_detail SHALL be:

Deploying or correcting OADP rolls backup components and adds backup I/O, but it does not reboot nodes or stop running VMs.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/backup_and_restore/index#configuring-oadp-with-openshift-virtualization`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/backup_and_restore/index#configuring-oadp-with-openshift-virtualization`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/backup_and_restore/index#configuring-oadp-with-openshift-virtualization`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/backup_and_restore/index#configuring-oadp-with-openshift-virtualization`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/backup_and_restore/index#configuring-oadp-with-openshift-virtualization`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/backup_and_restore/index#configuring-oadp-with-openshift-virtualization`.

A summary pattern containing `csv resources not found` SHALL produce `OADP CSV resources were not found.`.

#### Scenario: 7.4.tsr.4_8_5_3_1_oadp_operator loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_5_3_1_oadp_operator`
- THEN the title is `TSR OADP operator`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_5_3_5_cdi_image_upload_posture
`load_kb()` SHALL contain `7.4.tsr.4_8_5_3_5_cdi_image_upload_posture` from `7_4_layered.toml`. Title SHALL be `TSR CDI image upload posture`.

description SHALL be:

CDI (Containerized Data Importer) manages VM disk image imports and uploads.
Issues with CDI configuration prevent DataVolume provisioning, blocking new VM
creation and disk cloning operations.

recommendation SHALL be:

Keep CDI `Available=True`, `Progressing=False`, `Degraded=False`, with cdi-uploadproxy pods Ready. Restore CDI before the next disk import. Missing CR is n/a — running VMs are unaffected.

verification SHALL be:

1. Confirm CDI conditions: `Available=True`, `Progressing=False`, `Degraded=False`. If the CDI resource does not exist, it is informational.
   `oc get cdi -n openshift-cnv -o jsonpath='{range .items[*]}{range .status.conditions[*]}{.type}={.status}{"\n"}{end}{end}' 2>&1 | awk -F= '/not found|No resources found|have a resource type/{print "INFO n/a-cdi"; n=1; next} $1=="Available"{a=$2} $1=="Progressing"{p=$2} $1=="Degraded"{d=$2} END{if(n) exit; if(a==""&&p==""&&d=="") print "INFO n/a-cdi"; else print (a=="True" && p=="False" && d=="False"?"PASS":"FAIL"), "Available="a, "Progressing="p, "Degraded="d}'`
2. Confirm cdi-uploadproxy pods are Ready.
   `oc get pods -n openshift-cnv -l app=cdi-uploadproxy`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

CDI importer and upload components

impact_detail SHALL be:

CDI remediation rolls import or upload control pods and affects new image imports or uploads, but not already running VMs.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index`.

#### Scenario: 7.4.tsr.4_8_5_3_5_cdi_image_upload_posture loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_5_3_5_cdi_image_upload_posture`
- THEN the title is `TSR CDI image upload posture`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_1_1_logging_supported_configuration
`load_kb()` SHALL contain `7.4.tsr.4_1_1_logging_supported_configuration` from `7_4_layered.toml`. Title SHALL be `4.1.1. Logging Supported Configuration`.

description SHALL be:

This check evaluates whether the Cluster Logging operator is on the common channel for this OpenShift minor, whether its install succeeded, and whether it is current on that channel. If the operator is not installed, skip. A Cluster Log Forwarder without a Cluster Logging resource is forwarding-only and is still a supported logging mode.

recommendation SHALL be:

Keep the Cluster Logging operator on the common channel for this OpenShift minor. If Logging is in Maintenance Support, plan the next supported Logging and OpenShift pairing. When subscription approval is Manual and a newer operator is waiting, confirm it is compatible with the cluster, then approve the InstallPlan. A forwarding-only design (Cluster Log Forwarder without Cluster Logging) does not need LokiStack.

verification SHALL be:

1. List logging operator subscriptions in `openshift-logging`. Missing namespace is INFO — logging operator not installed.
   `oc get subscription -n openshift-logging 2>&1`
2. Print CSV phase and version. Succeeded is healthy; other phases need investigation.
   `oc get csv -n openshift-logging`
3. If Manual approval left a pending plan, print InstallPlans that are not Complete.
   `oc get installplan -n openshift-logging`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

openshift-logging operator

impact_detail SHALL be:

Approving an InstallPlan rolls operator pods; it does not reboot nodes.

Links SHALL be `default` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.18` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.19` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.20` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.21` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.22` -> `https://access.redhat.com/support/policy/updates/openshift_operators`.

#### Scenario: 7.4.tsr.4_1_1_logging_supported_configuration loads
- WHEN `get_entry` is called with `7.4.tsr.4_1_1_logging_supported_configuration`
- THEN the title is `4.1.1. Logging Supported Configuration`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_1_2_logging_storage_type
`load_kb()` SHALL contain `7.4.tsr.4_1_2_logging_storage_type` from `7_4_layered.toml`. Title SHALL be `TSR logging storage type`.

description SHALL be:

This check is LokiStack log-store type: spec.storage.secret.type and spec.storageClassName. An operator CSV without a LokiStack still means logs are not persisted.

recommendation SHALL be:

Set LokiStack store type and storageClassName so logs persist. Both <none> is a CR with no store — set them before treating Loki as unhealthy. An operator CSV without a LokiStack still means logs are not persisted.

verification SHALL be:

1. Print LokiStack store type and storageClassName. If the CRD is missing or empty, the command prints **INFO**. A row with both STORE and STORAGECLASS set is healthy; both showing <none> needs review.
   `oc get lokistack -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,STORE:.spec.storage.secret.type,STORAGECLASS:.spec.storageClassName 2>&1 | awk '/have a resource type|No resources found/{print "INFO n/a-lokistack"; n=1; next} NR==1{print "RESULT",$0; next} {r="PASS"; if($3=="<none>" && $4=="<none>") r="WARNING"; print r,$0} END{if(!n && NR==0) print "INFO n/a-lokistack"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

openshift-logging collector and log-store pods

impact_detail SHALL be:

Creating or changing a LokiStack rolls logging pods and can briefly interrupt log collection until the store is ready.

`finding_group` SHALL be `logging-not-configured`.

`finding_group_title` SHALL be `Cluster logging is not configured (no LokiStack)`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.18` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.19` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.20` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.21` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.22` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`.

A summary pattern containing `no instance configuration` SHALL produce `The Loki operator is installed, but no LokiStack is configured.`.

#### Scenario: 7.4.tsr.4_1_2_logging_storage_type loads
- WHEN `get_entry` is called with `7.4.tsr.4_1_2_logging_storage_type`
- THEN the title is `TSR logging storage type`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_1_4_logging_pod_status
`load_kb()` SHALL contain `7.4.tsr.4_1_4_logging_pod_status` from `7_4_layered.toml`. Title SHALL be `TSR logging pod status`.

description SHALL be:

This check confirms expected logging and Loki pods are running. Missing compactor, distributor, gateway, index-gateway, ingester, querier, or query-frontend pods usually mean logging is not configured yet, not that those images failed independently.

recommendation SHALL be:

Configure LokiStack storage first; then keep expected logging and Loki pods Running. Missing operand pods with no LokiStack means logging is not installed, not a CrashLoop. After a LokiStack exists, inspect the named non-Running pod.

verification SHALL be:

1. Check whether a LokiStack instance is configured.
   `oc get lokistack -A`
2. If a LokiStack exists, verify expected logging and Loki pods are Running.
   `oc get pods -n openshift-logging`
No LokiStack means logging is not configured yet (informational). After a LokiStack exists, non-Running expected pods are a failure.

impact SHALL be:

workload-shift

impact_scope SHALL be:

openshift-logging and Loki pods

impact_detail SHALL be:

Bringing the logging stack up starts new pods; it does not reboot nodes.

`finding_group` SHALL be `logging-not-configured`.

`finding_group_title` SHALL be `Cluster logging is not configured (no LokiStack)`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.18` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.19` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.20` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.21` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.22` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`.

A summary pattern containing `no pod found` SHALL produce `Expected logging/Loki pods are not running.`.

#### Scenario: 7.4.tsr.4_1_4_logging_pod_status loads
- WHEN `get_entry` is called with `7.4.tsr.4_1_4_logging_pod_status`
- THEN the title is `TSR logging pod status`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_1_5_2_loki_health
`load_kb()` SHALL contain `7.4.tsr.4_1_5_2_loki_health` from `7_4_layered.toml`. Title SHALL be `TSR Loki health`.

description SHALL be:

Loki health cannot be verified until a LokiStack instance exists. A **FAIL** for no instance configuration is a configuration gap, not a degraded running store.

recommendation SHALL be:

Treat no LokiStack as a configuration gap, not a degraded store. After a CR exists, keep Available/Ready true.

verification SHALL be:

1. Check for a LokiStack instance. An empty list means no instance is configured (informational). After an instance exists, False conditions are a failure.
   `oc get lokistack -A`

impact SHALL be:

workload-shift

impact_scope SHALL be:

LokiStack operands

impact_detail SHALL be:

Configuring LokiStack deploys store components and can briefly interrupt log query until they become ready.

`finding_group` SHALL be `logging-not-configured`.

`finding_group_title` SHALL be `Cluster logging is not configured (no LokiStack)`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.18` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.19` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.20` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.21` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`, `4.22` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.5/html-single/installing_logging/index`.

A summary pattern containing `no instance configuration` SHALL produce `Loki health cannot be verified because no LokiStack is configured.`.

#### Scenario: 7.4.tsr.4_1_5_2_loki_health loads
- WHEN `get_entry` is called with `7.4.tsr.4_1_5_2_loki_health`
- THEN the title is `TSR Loki health`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_1_6_cluster_log_forwarders
`load_kb()` SHALL contain `7.4.tsr.4_1_6_cluster_log_forwarders` from `7_4_layered.toml`. Title SHALL be `TSR cluster log forwarders`.

description SHALL be:

Multiple ClusterLogForwarder objects require the Vector collector. Fluentd does not support multi-forwarder. This check fails when more than one forwarder is configured without Vector.

recommendation SHALL be:

Switch the collector to Vector if more than one ClusterLogForwarder exists. Fluentd with multiple forwarders is unsupported and drops logs. One forwarder, or Vector with many, is the healthy state.

verification SHALL be:

1. List ClusterLogForwarder resources.
   `oc get clusterlogforwarder -A`
2. Print the collector type for each ClusterLogging instance.
   `oc get clusterlogging -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.collection.type`
Zero or one forwarders is healthy. More than one forwarder with a collector type other than vector is a failure.

impact SHALL be:

workload-shift

impact_scope SHALL be:

log collector pods

impact_detail SHALL be:

Changing collector type or forwarder count rolls collector pods and can drop logs until they reschedule.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.4/html/configuring_logging/configuring-log-forwarding`, `4.18` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.4/html/configuring_logging/configuring-log-forwarding`, `4.19` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.4/html/configuring_logging/configuring-log-forwarding`, `4.20` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.4/html/configuring_logging/configuring-log-forwarding`, `4.21` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.4/html/configuring_logging/configuring-log-forwarding`, `4.22` -> `https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.4/html/configuring_logging/configuring-log-forwarding`.

A summary pattern containing `multi log forwarder` SHALL produce `Multiple log forwarders are configured; that requires the Vector collector.`.

#### Scenario: 7.4.tsr.4_1_6_cluster_log_forwarders loads
- WHEN `get_entry` is called with `7.4.tsr.4_1_6_cluster_log_forwarders`
- THEN the title is `TSR cluster log forwarders`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_1_8_logging_security_context_constraints
`load_kb()` SHALL contain `7.4.tsr.4_1_8_logging_security_context_constraints` from `7_4_layered.toml`. Title SHALL be `TSR logging security context constraints`.

description SHALL be:

This check compares logging-related Security Context Constraints with the platform defaults, including the SCC used by node-exporter. An edited default SCC can weaken isolation or break logging/monitoring pods.

recommendation SHALL be:

Restore undocumented default SCC drift, including the SCC node-exporter uses. Record required exceptions and the pods that depend on them. Changing an SCC can bounce every pod bound to it.

verification SHALL be:

1. Identify the SCC used by node-exporter pods.
   `oc get pod -n openshift-monitoring -l app.kubernetes.io/name=node-exporter -o custom-columns=NAME:.metadata.name,SCC:.metadata.annotations.openshift\.io/scc`
2. Compare that SCC to the platform default. A match is healthy; undocumented drift is a failure.
   `oc get scc -o custom-columns=NAME:.metadata.name,PRIV:.allowPrivilegedContainer`

impact SHALL be:

workload-shift

impact_scope SHALL be:

pods bound to the altered SCC

impact_detail SHALL be:

Restoring or changing an SCC can bounce pods that use it; it does not reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/authentication_and_authorization/managing-pod-security-policies`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/authentication_and_authorization/managing-pod-security-policies`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/authentication_and_authorization/managing-pod-security-policies`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/authentication_and_authorization/managing-pod-security-policies`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/authentication_and_authorization/managing-pod-security-policies`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/authentication_and_authorization/managing-pod-security-policies`.

#### Scenario: 7.4.tsr.4_1_8_logging_security_context_constraints loads
- WHEN `get_entry` is called with `7.4.tsr.4_1_8_logging_security_context_constraints`
- THEN the title is `TSR logging security context constraints`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_1_1_1_identification_and_state
`load_kb()` SHALL contain `7.4.tsr.4_8_1_1_1_identification_and_state` from `7_4_layered.toml`. Title SHALL be `TSR CNV identification and state`.

description SHALL be:

This check verifies the OpenShift Virtualization control plane by reviewing the kubevirt-hyperconverged-operator CSV version and phase, along with the HyperConverged resource conditions. The expected healthy state is a Succeeded CSV with `Available=True`, `Progressing=False`, and `Degraded=False`. The absence of the openshift-cnv namespace indicates that OpenShift Virtualization is not installed and is recorded as N/A, not a VM failure.

recommendation SHALL be:

Ensure the kubevirt-hyperconverged-operator CSV is Succeeded and the HyperConverged resource reports `Available=True`, `Progressing=False`, and `Degraded=False`. Review the HyperConverged condition messages, related CSV/Subscription status, component pods, events, and logs to resolve failures.

verification SHALL be:

1. Print kubevirt-hyperconverged-operator CSV VERSION and PHASE. Succeeded is healthy. If the namespace does not exist, Virtualization is not installed.
   `oc get csv -n openshift-cnv -o custom-columns=NAME:.metadata.name,VERSION:.spec.version,PHASE:.status.phase 2>&1 | awk '/not found/{print "INFO n/a-cnv"; n=1; next} NR==1{next} $1 ~ /^kubevirt-hyperconverged-operator/ {print ($3=="Succeeded"?"PASS":"FAIL"), "NAME="$1, "VERSION="$2, "PHASE="$3; found=1} END{if(!n && !found) print "INFO n/a-cnv"}'`
2. Confirm HyperConverged conditions: `Available=True`, `Progressing=False`, `Degraded=False`. If the resource does not exist, Virtualization is not installed.
   `oc get hyperconverged kubevirt-hyperconverged -n openshift-cnv -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}' 2>&1 | awk -F= '/not found|have a resource type/{print "INFO n/a-cnv"; n=1; next} $1=="Available"{a=$2} $1=="Progressing"{p=$2} $1=="Degraded"{d=$2} END{if(n) exit; if(a==""&&p==""&&d=="") print "INFO n/a-cnv"; else print (a=="True" && p=="False" && d=="False"?"PASS":"FAIL"), "Available="a, "Progressing="p, "Degraded="d}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

openshift-cnv operator

impact_detail SHALL be:

Recording support state is informational; updating the virt operator rolls operator pods.

Links SHALL be `default` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.18` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.19` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.20` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.21` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.22` -> `https://access.redhat.com/support/policy/updates/openshift_operators`.

#### Scenario: 7.4.tsr.4_8_1_1_1_identification_and_state loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_1_1_1_identification_and_state`
- THEN the title is `TSR CNV identification and state`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_12_1_1_1_mtv_installation_and_state
`load_kb()` SHALL contain `7.4.tsr.4_12_1_1_1_mtv_installation_and_state` from `7_4_layered.toml`. Title SHALL be `TSR MTV installation and state`.

description SHALL be:

`ForkliftController` and related MTV operands must report Ready. A not-Ready controller means migrations cannot be reconciled even if the CSV is installed.

recommendation SHALL be:

Do not start or resume migration plans until every `ForkliftController` reports `Ready=True`. If the controller is not ready, review its status conditions and restore the Migration Toolkit for Virtualization operand pods to **Running** and **Ready**; resolve configuration, dependency, image-pull, or resource issues before retrying. A **Succeeded** Operator CSV only confirms installation. The `ForkliftController` and its operands must also be healthy before new migrations can be reconciled.

verification SHALL be:

1. Print `ForkliftController` conditions. Missing CR or namespace is informational. `Ready=False` or degraded conditions is a failure.
   `oc get forkliftcontroller -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{range .status.conditions[*]}{.type}={.status}{"\n"}{end}{end}'`
2. Inspect MTV operand pods. Non-Running pods are a failure.
   `oc get pods -n openshift-mtv`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

MTV controller pods

impact_detail SHALL be:

Fixing `ForkliftController` rolls MTV control-plane pods, not cluster nodes or guest VMs.

priority_hint SHALL be:

P3

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index`.

#### Scenario: 7.4.tsr.4_12_1_1_1_mtv_installation_and_state loads
- WHEN `get_entry` is called with `7.4.tsr.4_12_1_1_1_mtv_installation_and_state`
- THEN the title is `TSR MTV installation and state`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_12_1_1_2_operator_subscription_posture
`load_kb()` SHALL contain `7.4.tsr.4_12_1_1_2_operator_subscription_posture` from `7_4_layered.toml`. Title SHALL be `TSR MTV operator subscription posture`.

description SHALL be:

This check validates the Migration Toolkit for Virtualization (MTV) Operator subscription in the `openshift-mtv` namespace. A healthy subscription has `STATE=AtLatestKnown`, matching `INSTALLEDCSV` and `CURRENTCSV` values, a **Succeeded** `ClusterServiceVersion` (CSV), and no pending, failed, or manually unapproved `InstallPlan`. An `UpgradePending` state means a newer MTV Operator version is available but has not been installed. The cluster remains on its current CSV until the `InstallPlan` is approved and completes successfully. This check evaluates Operator Lifecycle Manager subscription and upgrade state only. `ForkliftController` readiness and MTV operand health are assessed separately.

recommendation SHALL be:

Review the pending `mtv-operator` `InstallPlan` and approve it only after confirming compatibility with the cluster, current MTV migration activity, and the approved maintenance window. Complete or pause active migrations before upgrading where required by the change plan. After approval, verify that the subscription returns to `AtLatestKnown`, `INSTALLEDCSV` matches `CURRENTCSV`, the installed MTV CSV reaches **Succeeded**, and no `InstallPlan` remains pending or failed. If the upgrade does not complete, investigate the `InstallPlan`, CSV conditions, operator pod logs, catalog availability, and namespace resource constraints before retrying.

verification SHALL be:

1. Print the mtv-operator subscription. Healthy when STATE is `AtLatestKnown` and INSTALLED equals CURRENT. If the namespace does not exist, MTV is not installed.
   `oc get subscription -n openshift-mtv -o custom-columns=NAME:.metadata.name,PACKAGE:.spec.name,CHANNEL:.spec.channel,STATE:.status.state,INSTALLED:.status.installedCSV,CURRENT:.status.currentCSV 2>&1 | awk '/not found|No resources found/{print "INFO n/a-mtv-subscription"; n=1; next} NR==1{next} {r="FAIL"; if($4=="AtLatestKnown" && $5==$6) r="PASS"; print r, "NAME="$1, "PACKAGE="$2, "CHANNEL="$3, "STATE="$4, "INSTALLED="$5, "CURRENT="$6} END{if(n) exit; if(NR<=1) print "INFO n/a-mtv-subscription"}'`
2. Print the MTV CSV PHASE. Succeeded is healthy; any other phase is a failure.
   `oc get csv -n openshift-mtv -o custom-columns=NAME:.metadata.name,PHASE:.status.phase 2>&1 | awk '/not found|No resources found/{print "INFO n/a-mtv-csv"; n=1; next} NR==1{next} $1 ~ /^mtv-operator/ {print ($2=="Succeeded"?"PASS":"FAIL"), "NAME="$1, "PHASE="$2; found=1} END{if(n) exit; if(!found) print "INFO n/a-mtv-csv"}'`
3. List `InstallPlan`s that are not Complete or not approved. All Complete and approved is healthy. If the namespace does not exist, MTV is not installed.
   `oc get installplan -n openshift-mtv -o custom-columns=NAME:.metadata.name,CSV:.spec.clusterServiceVersionNames,APPROVED:.spec.approved,PHASE:.status.phase 2>&1 | awk '/not found|No resources found/{print "INFO n/a-mtv-installplan"; n=1; next} NR==1{next} {r="PASS"; if($4!="Complete" || tolower($3)!="true") r="FAIL"; print r, "NAME="$1, "APPROVED="$3, "PHASE="$4} END{if(n) exit; if(NR<=1) print "INFO n/a-mtv-installplan"}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

openshift-mtv OLM resources

impact_detail SHALL be:

Approving an `InstallPlan` rolls the MTV operator; it does not reboot nodes.

priority_hint SHALL be:

P3

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/operators/index`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/operators/index`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/operators/index`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/operators/index`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/operators/index`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/operators/index`.

#### Scenario: 7.4.tsr.4_12_1_1_2_operator_subscription_posture loads
- WHEN `get_entry` is called with `7.4.tsr.4_12_1_1_2_operator_subscription_posture`
- THEN the title is `TSR MTV operator subscription posture`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_12_1_2_mtv_supported_configuration
`load_kb()` SHALL contain `7.4.tsr.4_12_1_2_mtv_supported_configuration` from `7_4_layered.toml`. Title SHALL be `TSR MTV supported configuration`.

description SHALL be:

This check validates the installed Migration Toolkit for Virtualization (MTV) Operator CSV version against the Red Hat OpenShift Operator lifecycle policy. It determines whether the specific installed MTV z-stream remains within its supported **Full Support** or **Maintenance Support** window. An expired maintenance window is a supportability failure for that operator version, even if the Operator remains installed and functional.

recommendation SHALL be:

Keep the installed MTV CSV on a version that remains within its applicable OpenShift Operator lifecycle window. If the current z-stream has left **Maintenance Support**, plan and execute an upgrade through a supported MTV subscription channel and upgrade path during an approved maintenance window.

verification SHALL be:

1. Print the mtv-operator CSV VERSION. If the namespace does not exist, MTV is not installed. Compare VERSION to the operator life-cycle policy.
   `oc get csv -n openshift-mtv -o custom-columns=NAME:.metadata.name,VERSION:.spec.version,PHASE:.status.phase 2>&1 | awk '/not found|No resources found/{print "INFO n/a-mtv-version"; n=1; next} NR==1{next} $1 ~ /^mtv-operator/ {print "INFO", "NAME="$1, "VERSION="$2, "PHASE="$3; found=1} END{if(n) exit; if(!found) print "INFO n/a-mtv-version"}'`
In-support VERSION is healthy; expired maintenance is a failure.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

openshift-mtv operator and ForkliftController

impact_detail SHALL be:

Upgrading MTV rolls operator pods; running VMs are not stopped by the operator upgrade itself.

priority_hint SHALL be:

P3

Links SHALL be `default` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.18` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.19` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.20` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.21` -> `https://access.redhat.com/support/policy/updates/openshift_operators`, `4.22` -> `https://access.redhat.com/support/policy/updates/openshift_operators`.

A summary pattern containing `no longer supported` SHALL produce `Migration Toolkit for Virtualization 2.8 is past maintenance support.`.

#### Scenario: 7.4.tsr.4_12_1_2_mtv_supported_configuration loads
- WHEN `get_entry` is called with `7.4.tsr.4_12_1_2_mtv_supported_configuration`
- THEN the title is `TSR MTV supported configuration`
- AND `content_from` is empty


### Requirement: KB 7.4.tsr.4_8_1_5_3_2_storage_checkup
`load_kb()` SHALL contain `7.4.tsr.4_8_1_5_3_2_storage_checkup` from `7_4_layered.toml`. Title SHALL be `TSR CNV storage checkup`.

description SHALL be:

This check reviews the result of the Kiagnose kubevirt-storage checkup, which validates that OpenShift Virtualization can provision and bind a test PersistentVolumeClaim (PVC) through the selected storage class. A successful checkup records `status.succeeded=true` and confirms that the test PVC was bound (`status.result.pvcBound`). The checkup result is stored in its ConfigMap; if the ConfigMap is absent, the storage checkup has not been run and the result is informational rather than evidence of a storage outage. Cluster-wide PVC health, the default StorageClass, and StorageProfile configuration are assessed separately.

recommendation SHALL be:

Treat `status.succeeded=true` with a bound test PVC as confirmation that the tested storage path is functioning for OpenShift Virtualization. If the checkup reports failure or the PVC does not bind, review `status.failureReason`. If no Kiagnose checkup ConfigMap exists, run the OpenShift Virtualization storage checkup when validation is required—especially after storage changes, CSI-driver updates, or an OpenShift upgrade. Do not classify a missing ConfigMap as a storage failure; it only indicates that this specific validation has not yet been performed.

verification SHALL be:

1. Print the kubevirt-storage checkup ConfigMap results: SUCCEEDED, PVCBBOUND, and FAILURE. A value of true for SUCCEEDED is healthy; false needs action. If the ConfigMap does not exist, the checkup has never been run.
   `oc get cm -A -l kiagnose/checkup-type=kubevirt-storage -o json | jq -r '.items[] | [.metadata.namespace, .metadata.name, (.data["status.succeeded"] // "-"), (.data["status.result.pvcBound"] // "-"), (if (.data["status.failureReason"] // "") == "" then "-" else .data["status.failureReason"] end)] | @tsv' | awk -F'\t' '{r="INFO"; if($3=="true") r="PASS"; else if($3=="false") r="FAIL"; print r, "NS="$1, "NAME="$2, "SUCCEEDED="$3, "PVCBBOUND="$4, "FAILURE="$5} END{if(NR==0) print "INFO n/a-storage-checkup"}'`
2. If this validation is required and the ConfigMap is missing, run the OpenShift Virtualization storage checkup using the procedure in the reference for this check.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

PVCs created by the storage checkup

impact_detail SHALL be:

Reading checkup results does not reboot nodes; re-running the checkup creates short-lived test VMs and PVCs.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/virtualization/index#virt-checking-storage-configuration_virt-storage-checkups`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/virtualization/index#virt-checking-storage-configuration_virt-running-cluster-checkups`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/virtualization/index#virt-checking-storage-configuration_virt-running-cluster-checkups`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/virtualization/index#virt-checking-storage-configuration_virt-running-cluster-checkups`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/virtualization/index#virt-checking-storage-configuration_virt-storage-checkups`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/virtualization/index#virt-checking-storage-configuration_virt-storage-checkups`.

#### Scenario: 7.4.tsr.4_8_1_5_3_2_storage_checkup loads
- WHEN `get_entry` is called with `7.4.tsr.4_8_1_5_3_2_storage_checkup`
- THEN the title is `TSR CNV storage checkup`
- AND `content_from` is empty


### Requirement: KB 7.5.alerts.critical
`load_kb()` SHALL contain `7.5.alerts.critical` from `7_5_cluster_health.toml`. Title SHALL be `Critical alerts`.

description SHALL be:

Critical alerts indicate conditions that require immediate attention. All
critical alerts should be investigated and resolved as quickly as possible.

recommendation SHALL be:

Resolve the firing critical alert immediately using the console runbook for that alert name. Empty Prometheus output is healthy. Do not silence or inhibit a critical alert to clear the finding.

verification SHALL be:

1. List firing critical alerts, showing `state`, `alertname`, and `severity`. Empty output means no critical alerts are firing:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.severity=="critical") | {state, alertname: .labels.alertname, severity: .labels.severity}'`
2. Look up runbooks in the OpenShift console under `Observe -> Alerting`.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

whatever the alertname names, often control plane

impact_detail SHALL be:

Clearing a firing critical alert follows that alert's runbook. Do not silence it. The remediating change is usually planned control-plane or node work.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.20` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.20/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`.

#### Scenario: 7.5.alerts.critical loads
- WHEN `get_entry` is called with `7.5.alerts.critical`
- THEN the title is `Critical alerts`
- AND `content_from` is empty


### Requirement: KB 7.5.alerts.warning
`load_kb()` SHALL contain `7.5.alerts.warning` from `7_5_cluster_health.toml`. Title SHALL be `Warning alerts`.

description SHALL be:

Warning alerts indicate conditions that may become critical if not addressed.
Review the firing warnings and decide whether they represent accepted risk or
require remediation.

recommendation SHALL be:

Classify each firing warning as accepted risk, tuning debt, or an incident. Do not treat the warning list as a page-now queue. Use the console runbook before changing thresholds or silences.

verification SHALL be:

1. List firing warning alerts, showing `state`, `alertname`, and `severity`:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.severity=="warning") | {state, alertname: .labels.alertname, severity: .labels.severity}'`
2. Classify each row as accepted risk, tuning debt, or a real incident. Look up runbooks under `Observe -> Alerting`.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

alert routing or the named component

impact_detail SHALL be:

Classifying a warning as accepted risk or tuning changes monitoring config and does not reboot nodes. The underlying fix follows the runbook.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.20` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.20/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`.

#### Scenario: 7.5.alerts.warning loads
- WHEN `get_entry` is called with `7.5.alerts.warning`
- THEN the title is `Warning alerts`
- AND `content_from` is empty


### Requirement: KB 7.5.pods.failed
`load_kb()` SHALL contain `7.5.pods.failed` from `7_5_cluster_health.toml`. Title SHALL be `Pod Health`.

description SHALL be:

This check lists pods in phase Failed or Unknown. Failed often includes completed Jobs and leftover debug pods. Unknown means the kubelet did not report status. It is not the CrashLoopBackOff check.

recommendation SHALL be:

Classify each Failed or Unknown pod before deleting it. Treat Job and `*-debug-*` pods as leftover work unless they belong to a required pipeline. Treat application pods as a workload failure: events, then logs. Do not use CrashLoopBackOff-only queries to close this finding. Delete a Failed Job pod only after the Job owner is understood; Unknown pods need node/kubelet investigation.

verification SHALL be:

1. List Failed pods. Empty output means none in Failed.
   `oc get pods -A --field-selector=status.phase=Failed`
2. List Unknown pods. Empty output means none in Unknown.
   `oc get pods -A --field-selector=status.phase=Unknown`
3. For each remaining application pod, print events.
   `oc describe pod <pod> -n <namespace>`

impact SHALL be:

workload-shift

impact_scope SHALL be:

Failed or Unknown application pods

impact_detail SHALL be:

Fixing or replacing a failed application pod restarts that workload. Unknown pods can require node or kubelet recovery in a maintenance window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`.

#### Scenario: 7.5.pods.failed loads
- WHEN `get_entry` is called with `7.5.pods.failed`
- THEN the title is `Pod Health`
- AND `content_from` is empty


### Requirement: KB 7.5.pods.crashloop
`load_kb()` SHALL contain `7.5.pods.crashloop` from `7_5_cluster_health.toml`. Title SHALL be `CrashLoopBackOff pods`.

description SHALL be:

This check identifies containers currently in the Waiting state with the reason `CrashLoopBackOff`, which means the container is repeatedly starting, terminating, and being restarted with an increasing delay between attempts. The output captures the waiting reason, last termination reason, exit code, and restart count to support root-cause analysis. Any container in `CrashLoopBackOff` is reported as **FAIL**.

recommendation SHALL be:

Investigate and remediate each `CrashLoopBackOff` container before deleting or restarting the pod. Review the container's waiting reason, previous termination reason, exit code, pod events, and prior container logs. Treat OOMKilled as termination evidence that requires memory-limit, workload-demand, or node-memory-pressure analysis; it is not a log message and should be correlated with events and container logs.

verification SHALL be:

1. List containers in `CrashLoopBackOff` with their wait reason, exit reason, exit code, and restart count. Any row in the output needs investigation. If none are in `CrashLoopBackOff` the command reports that:
   `oc get pods -A -o json | jq -r '.items[] | . as $p | (($p.status.containerStatuses // []) + ($p.status.initContainerStatuses // []))[] | [$p.metadata.namespace, $p.metadata.name, .name, (.state.waiting.reason // "-"), (.lastState.terminated.reason // "-"), ((.lastState.terminated.exitCode // "-")|tostring), (.restartCount|tostring)] | @tsv' | awk -F'\t' '$4=="CrashLoopBackOff"{print "FAIL", "NS="$1, "NAME="$2, "CONTAINER="$3, "WAIT="$4, "EXIT="$5, "EXITCODE="$6, "RESTARTS="$7; n=1} END{if(!n) print "INFO n/a-crashloop"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

CrashLoopBackOff containers

impact_detail SHALL be:

Correcting image, configuration, or memory limits restarts those pods. OOMKilled can also mean node memory pressure that needs capacity work.

`finding_group` SHALL be `crashloop-pods`.

`finding_group_title` SHALL be `CrashLoopBackOff pods`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#understanding-pod-error-states_investigating-pod-issues`.

#### Scenario: 7.5.pods.crashloop loads
- WHEN `get_entry` is called with `7.5.pods.crashloop`
- THEN the title is `CrashLoopBackOff pods`
- AND `content_from` is empty


### Requirement: KB 7.5.master_taints
`load_kb()` SHALL contain `7.5.master_taints` from `7_5_cluster_health.toml`. Title SHALL be `Control plane taints`.

description SHALL be:

On clusters with dedicated workers, control plane nodes should have the
`node-role.kubernetes.io/master:NoSchedule` taint so user workloads stay off
the control plane. Compact and single-node clusters are an exception: those
control-plane nodes are also workers, and the taint must not be added.

recommendation SHALL be:

On HA clusters with dedicated workers, taint masters NoSchedule so user pods stay off the control plane. Do not add that taint on compact or SNO — those masters are the workers and NoSchedule will strand workloads. Read taints and mastersSchedulable before you taint anything.

verification SHALL be:

1. List control-plane node taints:
   `oc get nodes -l node-role.kubernetes.io/control-plane -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints`
2. Check whether masters are configured as schedulable:
   `oc get scheduler cluster -o jsonpath='{.spec.mastersSchedulable}'`
3. On compact or SNO clusters, a missing NoSchedule taint is expected.
4. On HA clusters with dedicated workers, apply the NoSchedule taint:
   `oc adm taint nodes <node> node-role.kubernetes.io/master=:NoSchedule`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

control-plane scheduling

impact_detail SHALL be:

Adding the taint stops new user workloads from landing on control-plane nodes, but it does not reboot nodes or evict existing pods automatically.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-working-master-schedulable_nodes-nodes-managing`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-nodes-working-master-schedulable_nodes-nodes-managing`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-nodes-working-master-schedulable_nodes-nodes-managing`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-nodes-working-master-schedulable_nodes-nodes-managing`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-nodes-working-master-schedulable_nodes-nodes-managing`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-nodes-working-master-schedulable_nodes-nodes-managing`.

#### Scenario: 7.5.master_taints loads
- WHEN `get_entry` is called with `7.5.master_taints`
- THEN the title is `Control plane taints`
- AND `content_from` is empty


### Requirement: KB 7.5.k8s_version
`load_kb()` SHALL contain `7.5.k8s_version` from `7_5_cluster_health.toml`. Title SHALL be `Kubelet version skew`.

description SHALL be:

This check is kubeletVersion consistency. One KUBELET value cluster-wide = **PASS**. Mixed = **WARNING**. `STATE=Done` and `CURRENT=DESIRED` means the kubelet machine-config applied; anything else is a stuck kubelet rollout. MCP UPDATED/UPDATING/DEGRADED/PAUSED is the pool.

recommendation SHALL be:

Keep one kubelet version cluster-wide; mixed versions mean a stalled MachineConfig or upgrade. Finish the rollout until `STATE=Done` and `CURRENT=DESIRED`. Scoring is read-only; unpausing or completing a rollout drains nodes.

verification SHALL be:

1. List kubelet version per node. A single version across all nodes is healthy; mixed versions need investigation. If no nodes are returned the command reports it:
   `oc get nodes -o custom-columns=NAME:.metadata.name,KUBELET:.status.nodeInfo.kubeletVersion --no-headers | awk '{k[$2]++; print "NAME="$1, "KUBELET="$2} END{n=0; for(x in k)n++; if(NR==0) print "INFO n/a-kubelet"; else print (n<=1?"PASS":"WARNING"), "KUBELET_VALUES="n}'`
2. List machine-config state, current config, and desired config per node. `STATE=Done` with CURRENT matching DESIRED is healthy; otherwise the row needs action:
   `oc get nodes -o 'custom-columns=NAME:.metadata.name,STATE:.metadata.annotations.machineconfiguration\.openshift\.io/state,CURRENT:.metadata.annotations.machineconfiguration\.openshift\.io/currentConfig,DESIRED:.metadata.annotations.machineconfiguration\.openshift\.io/desiredConfig' --no-headers | awk '{r="PASS"; if($2!="Done" || $3!=$4) r="FAIL"; print r, "NAME="$1, "STATE="$2, "CURRENT="$3, "DESIRED="$4} END{if(NR==0) print "INFO n/a-kubelet"}'`
3. List `MachineConfigPool` update and degradation status. `DEGRADED=True` or DEGRADEDMC greater than 0 needs action. `UPDATING=True` is informational:
   `oc get mcp | awk 'NR==1{next} {r="PASS"; if($5=="True" || $9+0>0) r="FAIL"; else if($4=="True") r="INFO"; print r, "NAME="$1, "UPDATED="$3, "UPDATING="$4, "DEGRADED="$5, "READY="$7, "UPDATEDMC="$8, "DEGRADEDMC="$9}'`
4. List `MachineConfigPool` pause status. A paused pool needs action:
   `oc get mcp -o custom-columns=NAME:.metadata.name,PAUSED:.spec.paused --no-headers | awk '{r="PASS"; if($2=="true") r="FAIL"; print r, "NAME="$1, "PAUSED="$2}'`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the affected MachineConfigPool

impact_detail SHALL be:

Scoring versions is read-only. Completing a stalled kubelet or machine-config rollout drains and reboots lagging nodes one at a time. On compact 3-node clusters where all nodes serve as both control-plane and worker, this affects 100% of cluster capacity.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_configuration/index#troubleshooting-mco`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_configuration/index#troubleshooting-mco`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/postinstallation_configuration/index#troubleshooting-mco`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/postinstallation_configuration/index#troubleshooting-mco`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/machine_configuration/index#troubleshooting-mco`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/machine_configuration/index#troubleshooting-mco`.

#### Scenario: 7.5.k8s_version loads
- WHEN `get_entry` is called with `7.5.k8s_version`
- THEN the title is `Kubelet version skew`
- AND `content_from` is empty


### Requirement: KB 7.5.pruning.pods
`load_kb()` SHALL contain `7.5.pruning.pods` from `7_5_cluster_health.toml`. Title SHALL be `Pod pruning`.

description SHALL be:

This check counts terminated pods reported by the API: **Succeeded** pods and **Failed** pods. Counts at or below 200 succeeded and 50 failed are considered acceptable; higher counts generate a **WARNING** because terminated objects add API inventory clutter and can make troubleshooting noisier. Cluster-wide cleanup is controlled by the kube-controller-manager `terminated-pod-gc-threshold`. When unset, the default is 12,500 terminated pods, so normal garbage collection may not begin until far above this check’s thresholds.

recommendation SHALL be:

Keep terminated pod counts within the check thresholds by configuring TTL cleanup for recurring Jobs and pruning obsolete workload resources where appropriate. If terminated-pod accumulation is persistent across the cluster, review and tune `terminated-pod-gc-threshold` to a value appropriate for cluster size and workload churn. Counts above the threshold are a housekeeping and API-management warning, not an outage.

verification SHALL be:

1. Count Succeeded pods across the cluster. 200 or fewer is healthy; above that is a warning:
   `oc get pods -A --field-selector=status.phase=Succeeded --no-headers | awk 'END{c=NR; r=(c<=200?"PASS":"WARNING"); print r, "SUCCEEDED="c}'`
2. Count Failed pods across the cluster. 50 or fewer is healthy; above that is a warning:
   `oc get pods -A --field-selector=status.phase=Failed --no-headers | awk 'END{c=NR; r=(c<=50?"PASS":"WARNING"); print r, "FAILED="c}'`
3. Break down Succeeded and Failed pods by owner kind:
   `oc get pods -A -o json | jq -r '.items[] | select(.status.phase=="Succeeded" or .status.phase=="Failed") | [.status.phase, ((.metadata.ownerReferences[0].kind)//"none")] | @tsv' | awk -F'\t' '{c[$1 SUBSEP $2]++} END{for (x in c){split(x,a,SUBSEP); print "PHASE="a[1], "OWNERKIND="a[2], "COUNT="c[x]}}'`
4. Show the KubeControllerManager `terminated-pod-gc-threshold` setting. If unset, the default is 12500:
   `oc get kubecontrollermanager cluster -o json | jq -r '((.spec.unsupportedConfigOverrides // {}).extendedArguments // {})["terminated-pod-gc-threshold"][0] // ""' | awk '{v=$0} END{if(v=="") print "INFO GCTHRESHOLD=12500-default"; else print "PASS GCTHRESHOLD="v}'`
5. Preview a threshold change on KubeControllerManager. Remove --dry-`run=client` to apply; this restarts kube-controller-manager pods:
   `oc patch kubecontrollermanager cluster --type merge --dry-run=client -o json -p '{"spec":{"unsupportedConfigOverrides":{"extendedArguments":{"terminated-pod-gc-threshold":["200"]}}}}' | jq -r '.spec.unsupportedConfigOverrides.extendedArguments["terminated-pod-gc-threshold"][0]' | awk '{print "GCTHRESHOLD="$0}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

kube-controller-manager pods

impact_detail SHALL be:

Counting pods is read-only. Patching `terminated-pod-gc-threshold` restarts kube-controller-manager pods; it does not reboot nodes.

Links SHALL be `default` -> `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-garbage-collection`, `4.18` -> `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-garbage-collection`, `4.19` -> `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-garbage-collection`, `4.20` -> `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-garbage-collection`, `4.21` -> `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-garbage-collection`, `4.22` -> `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-garbage-collection`.

#### Scenario: 7.5.pruning.pods loads
- WHEN `get_entry` is called with `7.5.pruning.pods`
- THEN the title is `Pod pruning`
- AND `content_from` is empty


### Requirement: KB 7.5.pruning.jobs
`load_kb()` SHALL contain `7.5.pruning.jobs` from `7_5_cluster_health.toml`. Title SHALL be `Job pruning`.

description SHALL be:

Stale completed Jobs accumulate in etcd and slow API list operations. Add TTL
cleanup to Job specs so completed objects are removed automatically.

recommendation SHALL be:

Set ttlSecondsAfterFinished on Job templates, and cap CronJob history limits, so completed Jobs age out of etcd. Deleting rows by hand is a one-shot. Confirm a Job is no longer needed before you drop it.

verification SHALL be:

1. List completed Jobs across all namespaces:
   `oc get jobs -A`
2. Set `ttlSecondsAfterFinished` on Job templates so finished objects are removed automatically.
3. Cap CronJob `successfulJobsHistoryLimit` and `failedJobsHistoryLimit` to prevent unbounded growth.
4. Delete stale completed Jobs only after confirming they are no longer needed.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

completed job retention

impact_detail SHALL be:

Job TTL and history-limit changes affect cleanup behavior for completed jobs without disrupting running workloads.

Links SHALL be `default` -> `https://kubernetes.io/docs/concepts/workloads/controllers/ttlafterfinished/`, `4.18` -> `https://kubernetes.io/docs/concepts/workloads/controllers/ttlafterfinished/`, `4.19` -> `https://kubernetes.io/docs/concepts/workloads/controllers/ttlafterfinished/`, `4.20` -> `https://kubernetes.io/docs/concepts/workloads/controllers/ttlafterfinished/`, `4.21` -> `https://kubernetes.io/docs/concepts/workloads/controllers/ttlafterfinished/`, `4.22` -> `https://kubernetes.io/docs/concepts/workloads/controllers/ttlafterfinished/`.

#### Scenario: 7.5.pruning.jobs loads
- WHEN `get_entry` is called with `7.5.pruning.jobs`
- THEN the title is `Job pruning`
- AND `content_from` is empty


### Requirement: KB 7.5.registry_health
`load_kb()` SHALL contain `7.5.registry_health` from `7_5_cluster_health.toml`. Title SHALL be `Internal registry health`.

description SHALL be:

This reads the Image Registry Operator spec.managementState (not spec.storage.managementState). Managed means the Operator reconciles the registry. Unmanaged means the Operator ignores config changes — confirm that is intentional. Removed means the Operator has torn down the registry instance (the post-install default on platforms without shareable object storage until someone sets Managed and attaches storage) — confirm that is intentional.

recommendation SHALL be:

Keep Image Registry Operator `spec.managementState` at Managed when the platform should reconcile the registry. Leave Unmanaged only as an accepted exception. Removed is the post-install default until someone sets Managed and attaches storage. Changing state rolls registry pods.

verification SHALL be:

1. Show the Image Registry Operator managementState, replicas, and storage backend:
   `oc get configs.imageregistry.operator.openshift.io cluster -o custom-columns=STATE:.spec.managementState,REPLICAS:.spec.replicas,EMPTYDIR:.spec.storage.emptyDir,PVC:.spec.storage.pvc.claim`
2. Confirm `STATE` matches the cluster's intended usage.
3. If `Managed`, verify registry pods are running:
   `oc get pods -n openshift-image-registry`
4. If the cluster needs an Operator-reconciled registry and `STATE` is `Removed`, set `Managed` and configure storage. `Unmanaged` with user-provided storage is valid.

impact SHALL be:

workload-shift

impact_scope SHALL be:

image registry pods and internal image workflows

impact_detail SHALL be:

Changing registry state or storage rolls registry pods and can briefly interrupt builds or internal image pulls/pushes.

`finding_on_info` SHALL be true.

`finding_group` SHALL be `registry-management-state`.

`finding_group_title` SHALL be `Internal registry state`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/registry/configuring-registry-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/registry/configuring-registry-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/registry/configuring-registry-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/registry/configuring-registry-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/registry/configuring-registry-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/registry/configuring-registry-operator`.

A summary pattern containing `managementState: Unmanaged` SHALL produce `Image Registry Operator is Unmanaged; it will not reconcile registry config.`.

A summary pattern containing `managementState: Removed` SHALL produce `Image Registry Operator is Removed; there is no Operator-managed internal registry.`.

#### Scenario: 7.5.registry_health loads
- WHEN `get_entry` is called with `7.5.registry_health`
- THEN the title is `Internal registry health`
- AND `content_from` is empty


### Requirement: KB 7.5.pod_restarts
`load_kb()` SHALL contain `7.5.pod_restarts` from `7_5_cluster_health.toml`. Title SHALL be `Pod frequent restarts`.

description SHALL be:

This check identifies pods with a combined container restart count greater than 10. It measures total restarts across all containers in a pod and is intended to detect running workloads that are repeatedly cycling.

recommendation SHALL be:

Investigate pods with the highest restart totals first, using pod events and previous container logs to identify causes such as OOMKilled, failing probes, application errors, or invalid configuration. Correct the underlying issue and confirm that restart counts stop increasing.

verification SHALL be:

1. List pods sorted by total restart count across all containers. Any pod with more than 10 restarts needs investigation. If no pods exist the command reports it:
   `oc get pods -A -o json | jq -r '.items[] | [((.status.containerStatuses // []) | map(.restartCount) | add // 0), .metadata.name, .metadata.namespace] | @tsv' | sort -n | awk -F'\t' '{r="PASS"; if($1+0>10) r="WARNING"; print r, "RESTARTS="$1, "NAME="$2, "NS="$3} END{if(NR==0) print "INFO n/a-pod"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

pods with rising restart counts

impact_detail SHALL be:

Correcting image, configuration, or memory limits restarts those pods. OOMKilled can also mean node memory pressure that needs capacity work.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#reviewing-pod-status_investigating-pod-issues`.

#### Scenario: 7.5.pod_restarts loads
- WHEN `get_entry` is called with `7.5.pod_restarts`
- THEN the title is `Pod frequent restarts`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_6_node_role_values
`load_kb()` SHALL contain `7.5.tsr.5_6_node_role_values` from `7_5_cluster_health.toml`. Title SHALL be `TSR node-role values`.

description SHALL be:

This check verifies that each node has the correct role labels (master, worker, infra) and associated taints. Missing or incorrect labels can cause user workloads to run on control plane nodes, infrastructure workloads to land on worker nodes, or subscription entitlements to be miscounted.

recommendation SHALL be:

Keep node-role labels matching the intended worker, infra, and control-plane split. Missing infra labels is not a defect unless this cluster was meant to have dedicated infra nodes. On compact/SNO, masters are the workers — do not add NoSchedule there.

verification SHALL be:

1. List node role labels:
   `oc get nodes --show-labels | grep node-role`
2. If infra workloads should run on dedicated nodes, label them accordingly:
   `oc label node <node> node-role.kubernetes.io/infra=""`
3. Taint infra nodes to keep user workloads off them:
   `oc adm taint nodes <node> node-role.kubernetes.io/infra=:NoSchedule`
4. On HA clusters with dedicated workers, confirm control-plane nodes carry the NoSchedule taint. On compact or SNO clusters, a missing NoSchedule taint is expected.

impact SHALL be:

workload-shift

impact_scope SHALL be:

node scheduling and infra workload placement

impact_detail SHALL be:

Changing node roles or taints affects where future workloads land and may require workload migration or rollout to move existing infra pods.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_management/index#binding-infra-node-workloads-using-taints-tolerations_creating-infrastructure-machinesets`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_management/index#binding-infra-node-workloads-using-taints-tolerations_creating-infrastructure-machinesets`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/machine_management/index#binding-infra-node-workloads-using-taints-tolerations_creating-infrastructure-machinesets`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/machine_management/index#binding-infra-node-workloads-using-taints-tolerations_creating-infrastructure-machinesets`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/machine_management/index#binding-infra-node-workloads-using-taints-tolerations_creating-infrastructure-machinesets`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/machine_management/index#binding-infra-node-workloads-using-taints-tolerations_creating-infrastructure-machinesets`.

A summary pattern containing `NoSchedule` SHALL produce `Expected NoSchedule taint is missing on one or more nodes.`.

#### Scenario: 7.5.tsr.5_6_node_role_values loads
- WHEN `get_entry` is called with `7.5.tsr.5_6_node_role_values`
- THEN the title is `TSR node-role values`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_1_node_kubelet_health
`load_kb()` SHALL contain `7.5.tsr.5_1_node_kubelet_health` from `7_5_cluster_health.toml`. Title SHALL be `5.1. Node Kubelet Health`.

description SHALL be:

This check validates the Kubernetes node Ready condition. A node is healthy and available to accept pods only when `Ready=True`; `Ready=False` means the node is unhealthy and not accepting workloads, while `Ready=Unknown` means the control plane has stopped receiving kubelet heartbeats. Any state other than `Ready=True` is a node-availability failure and can disrupt scheduling, VM placement, live migration, and workload recovery. This check is limited to node readiness.

recommendation SHALL be:

Restore every node to `Ready=True` before relying on it for workload placement or VM operations. For each non-ready node, inspect its condition reason, recent events, kubelet and CRI-O status, node networking, certificate state, and Machine Config Operator status; cordon the node and migrate or drain workloads safely where appropriate before remediation.

verification SHALL be:

1. List each node and its STATUS. Ready is healthy; any other status needs action. If no nodes exist the command reports it:
   `oc get nodes --no-headers | awk '{r="PASS"; if($2!="Ready") r="FAIL"; print r, "NAME="$1, "STATUS="$2} END{if(NR==0) print "INFO n/a-node"}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

NotReady nodes and their workloads

impact_detail SHALL be:

Cordon, drain, then repair kubelet, CRI-O, or Machine Config. Node recovery can reboot that node and shift its workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`.

#### Scenario: 7.5.tsr.5_1_node_kubelet_health loads
- WHEN `get_entry` is called with `7.5.tsr.5_1_node_kubelet_health`
- THEN the title is `5.1. Node Kubelet Health`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_2_machine_config
`load_kb()` SHALL contain `7.5.tsr.5_2_machine_config` from `7_5_cluster_health.toml`. Title SHALL be `5.2. Machine Config`.

description SHALL be:

This check is MachineConfig drift: node STATE, CURRENT, and DESIRED, and MCP DEGRADED. `STATE=Done` and `CURRENT=DESIRED` = **PASS**. `DEGRADED=True` = **FAIL**.

recommendation SHALL be:

Bring every node CURRENT annotation to DESIRED, and clear MCP Degraded. This row is read-only; applying the desired config drains and reboots that pool.

verification SHALL be:

1. List each node's machine-config state, current config, and desired config. `STATE=Done` with CURRENT matching DESIRED is healthy; otherwise the row needs action. If no nodes exist the command reports it:
   `oc get nodes -o 'custom-columns=NAME:.metadata.name,STATE:.metadata.annotations.machineconfiguration\.openshift\.io/state,CURRENT:.metadata.annotations.machineconfiguration\.openshift\.io/currentConfig,DESIRED:.metadata.annotations.machineconfiguration\.openshift\.io/desiredConfig' --no-headers | awk '{r="PASS"; if($2!="Done" || $3!=$4) r="FAIL"; print r, "NAME="$1, "STATE="$2, "CURRENT="$3, "DESIRED="$4} END{if(NR==0) print "INFO n/a-node"}'`
2. List `MachineConfigPool` rendered config and degradation status. `DEGRADED=True` needs action; `UPDATING=True` is informational. If no pools exist the command reports it:
   `oc get mcp --no-headers | awk '{r="PASS"; if($5=="True") r="FAIL"; else if($4=="True") r="INFO"; print r, "NAME="$1, "CONFIG="$2, "UPDATED="$3, "UPDATING="$4, "DEGRADED="$5} END{if(NR==0) print "INFO n/a-mcp"}'`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the affected MachineConfigPool

impact_detail SHALL be:

Scoring drift is read-only. Applying a desired MachineConfig drains and reboots nodes in that pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/machine_configuration/index#understanding-the-machine-config-operator`.

#### Scenario: 7.5.tsr.5_2_machine_config loads
- WHEN `get_entry` is called with `7.5.tsr.5_2_machine_config`
- THEN the title is `5.2. Machine Config`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_3_operator_state
`load_kb()` SHALL contain `7.5.tsr.5_3_operator_state` from `7_5_cluster_health.toml`. Title SHALL be `5.3. Operator State`.

description SHALL be:

This check is ClusterOperator AVAILABLE, PROGRESSING, and DEGRADED. `AVAILABLE=True` `PROGRESSING=False` `DEGRADED=False` = **PASS**. Else **FAIL**.

recommendation SHALL be:

Restore ClusterOperators to `Available=True`, `Progressing=False`, `Degraded=False`. Read conditions on the degraded operator next; do not start from a cluster-wide `oc get co` dump.

verification SHALL be:

1. List each ClusterOperator with AVAILABLE, PROGRESSING, and DEGRADED columns. `AVAILABLE=True`, `PROGRESSING=False`, `DEGRADED=False` is healthy; any other combination needs action. If no operators exist the command reports it:
   `oc get co --no-headers | awk '{r="PASS"; if($3!="True" || $4!="False" || $5!="False") r="FAIL"; print r, "NAME="$1, "AVAILABLE="$3, "PROGRESSING="$4, "DEGRADED="$5} END{if(NR==0) print "INFO n/a-co"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

the degraded ClusterOperator's operands

impact_detail SHALL be:

Fixing the named dependency then reconciling the operator rolls its pods. It does not reboot nodes by itself; Machine Config, etcd, and network children can require a heavier window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#troubleshooting-operator-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#troubleshooting-operator-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#troubleshooting-operator-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#troubleshooting-operator-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#troubleshooting-operator-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#troubleshooting-operator-issues`.

#### Scenario: 7.5.tsr.5_3_operator_state loads
- WHEN `get_entry` is called with `7.5.tsr.5_3_operator_state`
- THEN the title is `5.3. Operator State`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_4_registry_health
`load_kb()` SHALL contain `7.5.tsr.5_4_registry_health` from `7_5_cluster_health.toml`. Title SHALL be `5.4. Registry Health`.

description SHALL be:

Validates internal image registry pod health, storage backend availability, and
managementState. A degraded registry blocks builds, ImageStream imports, and
internal image distribution.

recommendation SHALL be:

Restore registry pods and the image-registry ClusterOperator, and configure storage if it is missing. A degraded registry blocks builds and ImageStream imports. Operator managementState is ownership of the registry, not the storage backend.

verification SHALL be:

1. Check the image-registry ClusterOperator status. A healthy operator shows `AVAILABLE=True`, `PROGRESSING=False`, `DEGRADED=False`:
   `oc get co image-registry --no-headers | awk '{print ($3=="True" && $4=="False" && $5=="False"?"PASS":"FAIL"), $0}'`
2. Verify registry pods are running:
   `oc get pods -n openshift-image-registry`
3. Show the managementState and storage backend configuration:
   `oc get configs.imageregistry.operator.openshift.io cluster -o custom-columns=STATE:.spec.managementState,REPLICAS:.spec.replicas,EMPTYDIR:.spec.storage.emptyDir,PVC:.spec.storage.pvc.claim`

impact SHALL be:

workload-shift

impact_scope SHALL be:

image-registry pods and internal image workflows

impact_detail SHALL be:

Changing registry state or storage rolls registry pods and can briefly interrupt builds or internal image pulls/pushes.

`finding_group` SHALL be `registry-health-pods`.

`finding_group_title` SHALL be `Image registry health (pods and ClusterOperator)`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/registry/index#checking-the-status-of-registry-pods_accessing-the-registry`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/registry/index#checking-the-status-of-registry-pods_accessing-the-registry`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/registry/index#checking-the-status-of-registry-pods_accessing-the-registry`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/registry/index#checking-the-status-of-registry-pods_accessing-the-registry`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/registry/index#checking-the-status-of-registry-pods_accessing-the-registry`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/registry/index#checking-the-status-of-registry-pods_accessing-the-registry`.

#### Scenario: 7.5.tsr.5_4_registry_health loads
- WHEN `get_entry` is called with `7.5.tsr.5_4_registry_health`
- THEN the title is `5.4. Registry Health`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_5_pod_frequent_restarts
`load_kb()` SHALL contain `7.5.tsr.5_5_pod_frequent_restarts` from `7_5_cluster_health.toml`. Title SHALL be `5.5. Pod Frequent Restarts`.

description SHALL be:

This check identifies pods with a combined container restart count greater than 10. It measures total restarts across all containers in a pod and is intended to detect running workloads that are repeatedly cycling.

recommendation SHALL be:

Investigate pods with the highest restart totals first, using pod events and previous container logs to identify causes such as OOMKilled, failing probes, application errors, or invalid configuration. Correct the underlying issue and confirm that restart counts stop increasing.

verification SHALL be:

1. List pods sorted by total restart count across all containers. Any pod with more than 10 restarts needs investigation. If no pods exist the command reports it:
   `oc get pods -A -o json | jq -r '.items[] | [((.status.containerStatuses // []) | map(.restartCount) | add // 0), .metadata.name, .metadata.namespace] | @tsv' | sort -n | awk -F'\t' '{r="PASS"; if($1+0>10) r="WARNING"; print r, "RESTARTS="$1, "NAME="$2, "NS="$3} END{if(NR==0) print "INFO n/a-pod"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

pods with rising restart counts

impact_detail SHALL be:

Correcting image, configuration, or memory limits restarts those pods. OOMKilled can also mean node memory pressure that needs capacity work.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#reviewing-pod-status_investigating-pod-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#reviewing-pod-status_investigating-pod-issues`.

#### Scenario: 7.5.tsr.5_5_pod_frequent_restarts loads
- WHEN `get_entry` is called with `7.5.tsr.5_5_pod_frequent_restarts`
- THEN the title is `5.5. Pod Frequent Restarts`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_7_machine_config_pool
`load_kb()` SHALL contain `7.5.tsr.5_7_machine_config_pool` from `7_5_cluster_health.toml`. Title SHALL be `5.7. Machine Config Pool`.

description SHALL be:

Assesses `MachineConfigPool` update status and degradation. Pools stuck in
Updating or Degraded state block node rollouts and cluster upgrades.

recommendation SHALL be:

Resolve any Updating or Degraded `MachineConfigPool` condition before starting the next node rollout or cluster upgrade. First inspect the affected pool and node-level Machine Config Daemon errors to identify the cause; do not unpause the pool or increase `maxUnavailable` until it is understood and corrected, because the MCO cords, drains, applies configuration to, and often reboots affected nodes during rollout.

verification SHALL be:

1. List `MachineConfigPool` status:
   `oc get mcp`
2. Inspect any degraded pool for error details:
   `oc describe mcp <pool>`
3. List nodes that are updating or degraded:
   `oc get nodes -l node.openshift.io/os_id=rhcos --sort-by=.metadata.name`
4. Confirm `maxUnavailable` allows progress without over-draining capacity, especially on compact 3-node clusters.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the degraded or updating MachineConfigPool

impact_detail SHALL be:

Resolving MCP degradation may require the MCO to drain and reboot stuck nodes to complete configuration rollout.

`finding_group` SHALL be `mcp-pool-health`.

`finding_group_title` SHALL be `MachineConfigPool degraded or updating`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/machine_configuration/index#understanding-the-machine-config-operator`.

#### Scenario: 7.5.tsr.5_7_machine_config_pool loads
- WHEN `get_entry` is called with `7.5.tsr.5_7_machine_config_pool`
- THEN the title is `5.7. Machine Config Pool`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_8_machine_set
`load_kb()` SHALL contain `7.5.tsr.5_8_machine_set` from `7_5_cluster_health.toml`. Title SHALL be `5.8. Machine Set`.

description SHALL be:

Validates MachineSet desired vs actual replica counts and machine provisioning
state. Mismatched replicas or stuck machines indicate infrastructure provisioning
failures or capacity constraints.

recommendation SHALL be:

Bring MachineSet available count to desired, or treat empty as n/a on bare-metal UPI. Stuck machines are an infrastructure-provider problem (quota, PXE, BMC), not a scheduler problem.

verification SHALL be:

1. List MachineSets across all namespaces:
   `oc get machineset -A`
2. Compare desired versus available replica counts.
3. Inspect any failed machines for provisioning errors:
   `oc get machines -A`
   `oc describe machine <name> -n openshift-machine-api`
4. Check the underlying infrastructure provider for provisioning failures.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

infrastructure provider (quota, PXE, BMC)

impact_detail SHALL be:

Bringing MachineSet available count to desired is provisioner work, not the scheduler. Empty MachineSets on UPI are often not applicable.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`.

#### Scenario: 7.5.tsr.5_8_machine_set loads
- WHEN `get_entry` is called with `7.5.tsr.5_8_machine_set`
- THEN the title is `5.8. Machine Set`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_9_pod_disruption_budget
`load_kb()` SHALL contain `7.5.tsr.5_9_pod_disruption_budget` from `7_5_cluster_health.toml`. Title SHALL be `5.9. Pod Disruption Budget`.

description SHALL be:

Evaluates PodDisruptionBudget configuration to ensure voluntary disruptions
(drains, upgrades) cannot violate application availability requirements.
Missing or misconfigured PDBs risk downtime during maintenance.

recommendation SHALL be:

Review PDBs with `disruptionsAllowed=0` to determine whether they are intentionally protecting a workload or unnecessarily preventing node drains and upgrades. Where maintenance must proceed, restore sufficient healthy replicas and adjust the PDB's `minAvailable` or `maxUnavailable` so at least one voluntary disruption is permitted without violating the application's availability requirement. The absence of a PDB is not inherently a defect; however, confirm that every existing PDB selector matches the intended workload pods and that its availability settings reflect the application's actual redundancy and recovery capabilities.

verification SHALL be:

1. List all PodDisruptionBudgets with their allowed disruptions, minAvailable, and `maxUnavailable`:
   `oc get pdb -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,ALLOWED:.status.disruptionsAllowed,MIN:.spec.minAvailable,MAX:.spec.maxUnavailable`
2. Filter for PDBs that block voluntary eviction, where `ALLOWED` is 0:
   `oc get pdb -A --no-headers -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,ALLOWED:.status.disruptionsAllowed --no-headers | awk '$3=="0" {print}'`
3. Confirm each PDB selector matches the intended pods. Widening `maxUnavailable` or lowering minAvailable is the usual fix; deleting the PDB is a last resort.

impact SHALL be:

workload-shift

impact_scope SHALL be:

pods matching PDBs with `disruptionsAllowed=0`

impact_detail SHALL be:

A PDB with `disruptionsAllowed=0` blocks voluntary eviction of its matching pods, not a reboot directly. In practice, that can prevent the node from draining and therefore block or delay a controlled reboot, Machine Config rollout, node replacement, maintenance activity, or a rolling cluster upgrade on that node. Increasing allowed disruptions above zero, either by reducing `minAvailable` or increasing `maxUnavailable`, permits those evictions but can temporarily reduce the production workload's available replica count; only do so after confirming the application has enough replicas, capacity, health, and failover tolerance to remain available during the disruption. Do not bypass the PDB with forced eviction unless you explicitly accept the availability risk, because that can terminate protected pods regardless of the intended budget.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-pods-configuring-pod-distruption-about_nodes-pods-configuring`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-pods-configuring-pod-distruption-about_nodes-pods-configuring`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-pods-configuring-pod-distruption-about_nodes-pods-configuring`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-pods-configuring-pod-distruption-about_nodes-pods-configuring`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-pods-configuring-pod-distruption-about_nodes-pods-configuring`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-pods-configuring-pod-distruption-about_nodes-pods-configuring`.

#### Scenario: 7.5.tsr.5_9_pod_disruption_budget loads
- WHEN `get_entry` is called with `7.5.tsr.5_9_pod_disruption_budget`
- THEN the title is `5.9. Pod Disruption Budget`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_10_volume_mount_durations
`load_kb()` SHALL contain `7.5.tsr.5_10_volume_mount_durations` from `7_5_cluster_health.toml`. Title SHALL be `5.10. Volume Mount Durations`.

description SHALL be:

This check identifies slow or failed PVC attach and mount operations that delay pod startup. A pod cannot start until Kubernetes and the CSI driver attach, stage, and mount its volumes on the target node. Repeated `FailedAttachVolume`, `FailedMount`, or stuck `VolumeAttachment` conditions can delay application recovery, VM startup, node drains, and rollouts. This is an availability risk, not just a performance metric. Isolated delays can be transient, but recurring failures can materially extend recovery time—especially for VM disks, which must be available before the VM can boot.

recommendation SHALL be:

Treat recurring attach or mount failures as a storage availability issue. Review the affected pod events, PVC/PV, and `VolumeAttachment`, then check CSI controller and node-plugin health, storage-backend status, node-to-storage connectivity, access-mode compatibility, and whether the volume is still attached to a prior node. Do not delete `VolumeAttachment` objects, restart CSI components, resize volumes, or migrate workloads as a default fix. Force-detach only after confirming the previous node no longer uses the volume and the action is safe for the workload. After remediation, confirm the pod starts and the volume attaches and mounts within the required recovery time.

verification SHALL be:

1. List `FailedMount` and `FailedAttachVolume` events that indicate slow or stuck volume operations:
   `oc get events -A --field-selector reason=FailedMount`
   `oc get events -A --field-selector reason=FailedAttachVolume`
2. Verify CSI driver pods are running in the storage namespace and that the storage backend is responsive.
3. Check for `VolumeAttachment` objects stuck in an attaching state:
   `oc get volumeattachment`

impact SHALL be:

workload-shift

impact_scope SHALL be:

pods stuck on attach or mount

impact_detail SHALL be:

Online expansion may be transparent, but storage migration or cutover can require pod restart, rescheduling, or temporary workload movement.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#persistent-storage-csi`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#persistent-storage-csi`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#persistent-storage-csi`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#persistent-storage-csi`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#persistent-storage-csi`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#persistent-storage-csi`.

#### Scenario: 7.5.tsr.5_10_volume_mount_durations loads
- WHEN `get_entry` is called with `7.5.tsr.5_10_volume_mount_durations`
- THEN the title is `5.10. Volume Mount Durations`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_11_health_related_alerts
`load_kb()` SHALL contain `7.5.tsr.5_11_health_related_alerts` from `7_5_cluster_health.toml`. Title SHALL be `5.11. Health Related Alerts`.

description SHALL be:

Parent section covering health-related alerts including control plane, node,
and overcommit alert categories. Active alerts signal conditions that may
degrade cluster stability or workload reliability.

recommendation SHALL be:

This parent is the compact alert table. Scored recommendations live on the control-plane, node-pressure, and overcommit alert children.

verification SHALL be:

1. List all firing alerts, showing `state`, `alertname`, and `severity`:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {state, alertname: .labels.alertname, severity: .labels.severity}'`
2. Control-plane, node, and overcommit breakdowns are in the 5.11.x sub-checks.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.20` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.20/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`.

#### Scenario: 7.5.tsr.5_11_health_related_alerts loads
- WHEN `get_entry` is called with `7.5.tsr.5_11_health_related_alerts`
- THEN the title is `5.11. Health Related Alerts`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_11_1_control_plane_alerts
`load_kb()` SHALL contain `7.5.tsr.5_11_1_control_plane_alerts` from `7_5_cluster_health.toml`. Title SHALL be `5.11.1. Control Plane Alerts`.

description SHALL be:

Evaluates alerts specific to control plane components — API server, etcd,
scheduler, and controller-manager. Control plane alerts indicate conditions
that can affect cluster-wide API responsiveness and scheduling.

recommendation SHALL be:

Resolve firing alerts from openshift-etcd and openshift-kube-* using the alertname runbook. A firing critical here is cluster-wide; next reads are etcd health and API latency.

verification SHALL be:

1. List alerts from control-plane namespaces (openshift-etcd, openshift-kube-*), showing state, alertname, and severity:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.namespace != null and (.labels.namespace | test("openshift-etcd|openshift-kube"))) | {state, alertname: .labels.alertname, severity: .labels.severity}'`
2. Cross-reference firing alerts with etcd health, API server latency, and scheduler queue depth.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

openshift-etcd and openshift-kube-*

impact_detail SHALL be:

Fixing etcd disk-performance problems usually requires control-plane infrastructure or storage changes that can reduce API capacity while nodes are remediated.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.20` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.20/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`.

#### Scenario: 7.5.tsr.5_11_1_control_plane_alerts loads
- WHEN `get_entry` is called with `7.5.tsr.5_11_1_control_plane_alerts`
- THEN the title is `5.11.1. Control Plane Alerts`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_11_2_node_alerts
`load_kb()` SHALL contain `7.5.tsr.5_11_2_node_alerts` from `7_5_cluster_health.toml`. Title SHALL be `5.11.2. Node Alerts`.

description SHALL be:

This check is node READY and MEMORY/DISK/PID pressure. `READY=True` and pressures False = **PASS**. Else **FAIL**.

recommendation SHALL be:

Restore `Ready=True` and MEMORY/DISK/PID pressure False on every node. Pressure True means the kubelet is protecting the node — find the consumer before you add more workload.

verification SHALL be:

1. List each node with READY, MEMORY pressure, DISK pressure, and PID pressure. `READY=True` with all pressures False is healthy; any other combination needs action. If no nodes exist the command reports it. Quote the custom-columns value so bash does not parse the jsonpath:
   `oc get nodes -o 'custom-columns=NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status,MEMORY:.status.conditions[?(@.type=="MemoryPressure")].status,DISK:.status.conditions[?(@.type=="DiskPressure")].status,PID:.status.conditions[?(@.type=="PIDPressure")].status' --no-headers | awk '{r="PASS"; if($2!="True" || $3!="False" || $4!="False" || $5!="False") r="FAIL"; print r, "NAME="$1, "READY="$2, "MEMORY="$3, "DISK="$4, "PID="$5} END{if(NR==0) print "INFO n/a-node"}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

nodes with Ready false or MEMORY, DISK, or PID pressure

impact_detail SHALL be:

Pressure True means the kubelet is protecting the node. Finding the consumer or adding capacity can require a drain or node replacement.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-nodes-viewing-listing_nodes-nodes-viewing`.

#### Scenario: 7.5.tsr.5_11_2_node_alerts loads
- WHEN `get_entry` is called with `7.5.tsr.5_11_2_node_alerts`
- THEN the title is `5.11.2. Node Alerts`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_11_3_overcommit_alerts
`load_kb()` SHALL contain `7.5.tsr.5_11_3_overcommit_alerts` from `7_5_cluster_health.toml`. Title SHALL be `5.11.3. Overcommit Alerts`.

description SHALL be:

This check evaluates CPU and memory request overcommit using Overcommit/Quota alerts and the ratio of requested resources to node allocatable capacity. A ratio greater than 1.0 is a **WARNING** because scheduled requests exceed available allocatable resources.

recommendation SHALL be:

Review workloads scheduled to node pools where CPU or memory requests exceed available allocatable capacity, then right-size requests based on sustained demand or add node capacity. Do not rely on `oc adm top` to assess this condition, as it reports current usage rather than scheduler reservations and can show idle nodes even when the cluster is overcommitted. Avoid increasing allocatable values solely to suppress the alert.

verification SHALL be:

1. List firing Overcommit or Quota alerts by state, alertname, and severity. If none are firing the command reports it:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | select(.labels.alertname | test("Overcommit|Quota"; "i")) | [.state, .labels.alertname, .labels.severity] | @tsv' | awk -F'\t' '{print "WARNING", "STATE="$1, "ALERT="$2, "SEVERITY="$3} END{if(NR==0) print "INFO n/a-overcommit-alert"}'`
2. Show CPU request-to-allocatable ratio per node. A ratio above 1 means CPU requests exceed allocatable capacity. If no data is returned the command reports it:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=sum by (node) (kube_pod_container_resource_requests{resource="cpu"}) / sum by (node) (kube_node_status_allocatable{resource="cpu"})' | jq -r '.data.result[] | [.metric.node, .value[1]] | @tsv' | awk -F'\t' '{r="PASS"; if($2+0>1) r="WARNING"; printf "%s NODE=%s CPU_REQ_RATIO=%.2f\n", r, $1, $2} END{if(NR==0) print "INFO n/a-cpu-overcommit"}'`
3. Show memory request-to-allocatable ratio per node. A ratio above 1 means memory requests exceed allocatable capacity. If no data is returned the command reports it:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=sum by (node) (kube_pod_container_resource_requests{resource="memory"}) / sum by (node) (kube_node_status_allocatable{resource="memory"})' | jq -r '.data.result[] | [.metric.node, .value[1]] | @tsv' | awk -F'\t' '{r="PASS"; if($2+0>1) r="WARNING"; printf "%s NODE=%s MEM_REQ_RATIO=%.2f\n", r, $1, $2} END{if(NR==0) print "INFO n/a-mem-overcommit"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads whose requests exceed allocatable

impact_detail SHALL be:

Right-sizing requests from sustained demand reschedules or rolls those workloads. Adding nodes is a maintenance window. Do not raise allocatable to hide the alert.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`.

#### Scenario: 7.5.tsr.5_11_3_overcommit_alerts loads
- WHEN `get_entry` is called with `7.5.tsr.5_11_3_overcommit_alerts`
- THEN the title is `5.11.3. Overcommit Alerts`
- AND `content_from` is empty


### Requirement: KB 7.5.tsr.5_12_dns_health
`load_kb()` SHALL contain `7.5.tsr.5_12_dns_health` from `7_5_cluster_health.toml`. Title SHALL be `5.12. DNS Health`.

description SHALL be:

Validates CoreDNS pod health, DNS resolution latency, and DNS operator status.
DNS failures cascade into service discovery issues, health probe failures,
and operator degradation across the entire cluster.

recommendation SHALL be:

Keep dns.operator default `Available=True`, `Progressing=False`, `Degraded=False`. DNS failures cascade into service discovery, probes, and operators. SERVFAIL in CoreDNS logs is the usual next read after a degraded operator.

verification SHALL be:

1. Check `dns.operator default` status. Healthy means `Available=True`, `Progressing=False`, `Degraded=False`:
   `oc get dns.operator default -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}' | awk -F= '$1=="Available"{a=$2} $1=="Progressing"{p=$2} $1=="Degraded"{d=$2} END{print (a=="True" && p=="False" && d=="False"?"PASS":"FAIL"), "Available="a, "Progressing="p, "Degraded="d}'`
2. If the operator is not healthy, list its conditions for details:
   `oc get dns.operator default -o jsonpath='{range .status.conditions[*]}{.type}={.status} reason={.reason}{"\n"}{end}'`
3. Verify DNS pods are running:
   `oc get pods -n openshift-dns`
4. Check CoreDNS logs for SERVFAIL entries:
   `oc -n openshift-dns logs -l dns.operator.openshift.io/daemonset-dns --tail=100`

impact SHALL be:

workload-shift

impact_scope SHALL be:

dns.operator and CoreDNS

impact_detail SHALL be:

Restoring dns.operator default rolls CoreDNS and can briefly break name resolution. It does not reboot nodes.

`finding_group` SHALL be `dns-operator-health`.

`finding_group_title` SHALL be `DNS Operator / CoreDNS health`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_operators/index#nw-dns-operator_dns-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_operators/index#nw-dns-operator_dns-operator`.

#### Scenario: 7.5.tsr.5_12_dns_health loads
- WHEN `get_entry` is called with `7.5.tsr.5_12_dns_health`
- THEN the title is `5.12. DNS Health`
- AND `content_from` is empty


### Requirement: KB 7.6.csr_pending
`load_kb()` SHALL contain `7.6.csr_pending` from `7_6_day2.toml`. Title SHALL be `Pending CSRs`.

description SHALL be:

Pending CSRs typically indicate new nodes waiting for certificate approval. In
manual approval mode they block node join; in auto-approve mode they often
indicate a bootstrap or node-health issue.

recommendation SHALL be:

Approve pending CSRs only for REQUESTORs you trust so nodes can join in manual approval mode. An empty list means there is nothing waiting — approved CSRs are garbage-collected. A Denied CSR needs a new request; do not re-approve a Denied CSR to clear the finding.

verification SHALL be:

1. List certificate signing requests. **FAIL** if CONDITION is Pending or Denied; **PASS** if Approved or the list is empty (nothing waiting). If the CSR API is missing, the command prints **INFO** — skip.
   `oc get csr --no-headers 2>&1 | awk '/have a resource type/{print "INFO n/a-csr"; n=1; next} /No resources found/{print "PASS none-pending"; n=1; next} {r="PASS"; if($NF=="Pending" || $NF=="Denied") r="FAIL"; print r, "NAME="$1, "REQUESTOR="$4, "CONDITION="$NF} END{if(!n && NR==0) print "PASS none-pending"}'`
2. On **FAIL** Pending, inspect REQUESTOR and approve only trusted node CSRs.
   `oc adm certificate approve <csr>`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

pending node joins and certificate approval

impact_detail SHALL be:

Approving trusted CSRs allows nodes to finish joining the cluster without rebooting existing nodes or evicting workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-approve-csrs_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-approve-csrs_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-approve-csrs_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-approve-csrs_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-approve-csrs_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-approve-csrs_installing-platform-agnostic`.

#### Scenario: 7.6.csr_pending loads
- WHEN `get_entry` is called with `7.6.csr_pending`
- THEN the title is `Pending CSRs`
- AND `content_from` is empty


### Requirement: KB 7.6.proxy
`load_kb()` SHALL contain `7.6.proxy` from `7_6_day2.toml`. Title SHALL be `Cluster-wide proxy`.

description SHALL be:

Cluster-wide proxy configuration affects operator updates, Telemetry, and
Red Hat Insights. Ensure `noProxy` includes the cluster network CIDRs to avoid
routing loops and unnecessary proxy traversal.

recommendation SHALL be:

Put service, pod, and machine CIDRs in `noProxy` before you patch the cluster Proxy. Changing the Proxy object rolls every node through the MCO. Watch `MachineConfigPool`s until `UPDATED=True` after the patch.

verification SHALL be:

1. Print the Proxy object endpoints (httpProxy, httpsProxy, noProxy).
   `oc get proxy cluster -o jsonpath='{.spec.httpProxy}{"\t"}{.spec.httpsProxy}{"\t"}{.spec.noProxy}{"\n"}'`
2. Print the trustedCA ConfigMap name.
   `oc get proxy cluster -o jsonpath='{.spec.trustedCA.name}{"\n"}'`
3. Include service, pod, and machine-network CIDRs plus internal endpoints in `noProxy` before applying changes.
4. After patching, watch `MachineConfigPool`s until all show `UPDATED=True`.
   `oc get mcp`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

cluster-wide nodes and system egress

impact_detail SHALL be:

Changing the Proxy object causes the Machine Config Operator to roll and reboot nodes so system components inherit the new proxy settings.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/configuring_network_settings/index#nw-proxy-configure-object_config-cluster-wide-proxy`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/configuring_network_settings/index#nw-proxy-configure-object_config-cluster-wide-proxy`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/configuring_network_settings/index#nw-proxy-configure-object_config-cluster-wide-proxy`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/configuring_network_settings/index#nw-proxy-configure-object_config-cluster-wide-proxy`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/configuring_network_settings/index#nw-proxy-configure-object_config-cluster-wide-proxy`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/configuring_network_settings/index#nw-proxy-configure-object_config-cluster-wide-proxy`.

#### Scenario: 7.6.proxy loads
- WHEN `get_entry` is called with `7.6.proxy`
- THEN the title is `Cluster-wide proxy`
- AND `content_from` is empty


### Requirement: KB 7.6.rq
`load_kb()` SHALL contain `7.6.rq` from `7_6_day2.toml`. Title SHALL be `Resource quotas`.

description SHALL be:

ResourceQuotas limit total resource consumption per namespace. Without them, a
single namespace can consume cluster capacity and starve other tenants.

recommendation SHALL be:

Set a ResourceQuota so one namespace cannot starve the rest of the cluster. Quota hits new creates and scale-outs, not pods that are already Running. Size to expected CPU, memory, and object count; a project-request template covers the next namespace.

verification SHALL be:

1. Show the ResourceQuota detail for a namespace. Review whether usage is approaching HARD limits.
   `oc describe quota -n <ns>`
2. Apply ResourceQuotas to tenant namespaces sized to expected CPU, memory, storage, and object count.
3. Use project templates so new namespaces receive quotas automatically.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

namespace admission and capacity guardrails

impact_detail SHALL be:

Quota changes take effect immediately for new creates and scale-outs, but they do not restart nodes or stop already running workloads.

priority_hint SHALL be:

P3

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#compute-resource-quotas`.

#### Scenario: 7.6.rq loads
- WHEN `get_entry` is called with `7.6.rq`
- THEN the title is `Resource quotas`
- AND `content_from` is empty


### Requirement: KB 7.6.upgrade.history
`load_kb()` SHALL contain `7.6.upgrade.history` from `7_6_day2.toml`. Title SHALL be `Upgrade history`.

description SHALL be:

Regular upgrade cadence is important for security patching and supportability.
Long delays between z-stream or minor upgrades increase lifecycle and security
risk.

recommendation SHALL be:

Plan the next hop on the Upgrade Graph before you apply. Completed history is the healthy end state; any other STATE is a failed or incomplete upgrade. If the cluster is multiple minors behind, test the supported path in non-production and schedule a maintenance window. Partial history is not cleared by ignoring it.

verification SHALL be:

1. Print STATE, VERSION, and COMPLETED from ClusterVersion history. **PASS** if STATE is Completed; **FAIL** for any other STATE.
   `oc get clusterversion version -o jsonpath='{range .status.history[*]}{.state}{"\t"}{.version}{"\t"}{.completionTime}{"\n"}{end}' | awk '{print ($1=="Completed"?"PASS":"FAIL"), "STATE="$1, "VERSION="$2, "COMPLETED="$3}'`
2. Use the OCP Upgrade Graph to plan the next supported update path.
3. If the cluster is multiple releases behind, test the target path in non-production and schedule a maintenance window before applying.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster-wide

impact_detail SHALL be:

Addressing stale upgrade history usually means performing a cluster upgrade, which rolls operators, nodes, and workloads over time.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`.

#### Scenario: 7.6.upgrade.history loads
- WHEN `get_entry` is called with `7.6.upgrade.history`
- THEN the title is `Upgrade history`
- AND `content_from` is empty


### Requirement: KB 7.6.apiserver.tls
`load_kb()` SHALL contain `7.6.apiserver.tls` from `7_6_day2.toml`. Title SHALL be `API server TLS profile`.

description SHALL be:

The TLS security profile controls which cipher suites and TLS versions are
accepted by the API server and other components. `Old` should not be used in
production unless compatibility requirements are explicitly documented.

recommendation SHALL be:

Keep API `tlsSecurityProfile` at Intermediate. Unset is that OpenShift default and is acceptable. Old is too weak for production; Custom means you own the cipher set. Patching rolls API servers; confirm clients support the cipher set first.

verification SHALL be:

1. Print the TLS security profile TYPE on the API server. **PASS** if empty, Intermediate, or Modern; **FAIL** if Old; **INFO** if Custom.
   `oc get apiserver cluster -o custom-columns=TYPE:.spec.tlsSecurityProfile.type --no-headers | awk '{t=$1; r="PASS"; if(t=="Old") r="FAIL"; if(t=="Custom") r="INFO"; if(t=="<none>"||t=="") t="default-Intermediate"; print r, "TYPE="t}'`
2. If TYPE is Old, patch to Intermediate (this rolls API servers).
   `oc patch apiserver cluster --type=merge -p '{"spec":{"tlsSecurityProfile":{"type":"Intermediate"}}}'`
3. Confirm external clients support the target cipher set before applying. Custom profiles stay **INFO** until the cipher set is documented.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

API server and related control-plane components

impact_detail SHALL be:

TLS profile changes propagate across multiple control-plane components and trigger an operator-managed rollout that can briefly reset API connections.

`finding_group` SHALL be `apiserver-tls`.

`finding_group_title` SHALL be `API server TLS profile`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#tls-profiles-kubernetes-configuring_tls-security-profiles`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#tls-profiles-kubernetes-configuring_tls-security-profiles`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#tls-profiles-kubernetes-configuring_tls-security-profiles`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#tls-profiles-kubernetes-configuring_tls-security-profiles`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#tls-profiles-kubernetes-configuring_tls-security-profiles`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#tls-profiles-kubernetes-configuring_tls-security-profiles`.

#### Scenario: 7.6.apiserver.tls loads
- WHEN `get_entry` is called with `7.6.apiserver.tls`
- THEN the title is `API server TLS profile`
- AND `content_from` is empty


### Requirement: KB 7.6.apiserver.audit
`load_kb()` SHALL contain `7.6.apiserver.audit` from `7_6_day2.toml`. Title SHALL be `API server audit profile`.

description SHALL be:

Audit logging is essential for compliance and incident investigation. Higher
audit profiles collect more detail but require deliberate sizing and retention
planning for log storage.

recommendation SHALL be:

Leave audit at metadata-only unless compliance requires `WriteRequestBodies` or `AllRequestBodies`. Those profiles roll API servers. Read the current profile before you patch, and size audit storage before you raise verbosity.

verification SHALL be:

1. Print the current audit profile on the API server.
   `oc get apiserver cluster -o jsonpath='{.spec.audit.profile}'`
2. `Default` records metadata only. For compliance that needs request bodies, set `WriteRequestBodies` or `AllRequestBodies`.
   `oc patch apiserver cluster --type=merge -p '{"spec":{"audit":{"profile":"WriteRequestBodies"}}}'`
3. Size audit log storage before increasing verbosity.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

API server audit pipeline

impact_detail SHALL be:

Audit-profile changes roll API server configuration and can briefly reset API connections while control-plane pods reconcile.

`finding_group` SHALL be `apiserver-audit`.

`finding_group_title` SHALL be `API server audit profile`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#configuring-audit-policy_audit-log-policy-config`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#configuring-audit-policy_audit-log-policy-config`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#configuring-audit-policy_audit-log-policy-config`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#configuring-audit-policy_audit-log-policy-config`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#configuring-audit-policy_audit-log-policy-config`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#configuring-audit-policy_audit-log-policy-config`.

#### Scenario: 7.6.apiserver.audit loads
- WHEN `get_entry` is called with `7.6.apiserver.audit`
- THEN the title is `API server audit profile`
- AND `content_from` is empty


### Requirement: KB 7.6.namespaces
`load_kb()` SHALL contain `7.6.namespaces` from `7_6_day2.toml`. Title SHALL be `Namespace hygiene`.

description SHALL be:

Namespace sprawl increases management overhead and attack surface. Regularly
audit namespaces for activity and remove ones that are no longer in use.

recommendation SHALL be:

Delete unused namespaces only after you confirm nothing in them is still referenced. Do not delete `openshift-*` or `kube-*`. Archive manifests first; confirm the project is idle before `oc delete ns`.

verification SHALL be:

1. List all namespaces. Look for inactive projects, abandoned test environments, and stale operator remnants.
   `oc get ns`
2. Delete only namespaces confirmed unused.
3. Archive any manifests or data that must be preserved before deletion.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

targeted unused namespaces

impact_detail SHALL be:

Deleting a namespace permanently removes the resources in that namespace, so confirm it is inactive first; other namespaces are unaffected.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/building_applications/index#deleting-a-project-using-the-CLI_projects`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/building_applications/index#deleting-a-project-using-the-CLI_projects`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/building_applications/index#deleting-a-project-using-the-CLI_projects`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/building_applications/index#deleting-a-project-using-the-CLI_projects`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/building_applications/index#deleting-a-project-using-the-CLI_projects`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/building_applications/index#deleting-a-project-using-the-CLI_projects`.

#### Scenario: 7.6.namespaces loads
- WHEN `get_entry` is called with `7.6.namespaces`
- THEN the title is `Namespace hygiene`
- AND `content_from` is empty


### Requirement: KB 7.6.limitranges
`load_kb()` SHALL contain `7.6.limitranges` from `7_6_day2.toml`. Title SHALL be `LimitRanges`.

description SHALL be:

LimitRanges enforce default resource requests and limits on containers.
Without them, workloads can bypass namespace-level guardrails and create noisy
neighbor problems.

recommendation SHALL be:

Add LimitRanges so pods pick default requests and limits and cannot skip namespace quota. Existing pods keep their spec; new or updated pods pick up the defaults.

verification SHALL be:

1. List LimitRanges across all namespaces to review existing coverage.
   `oc get limitrange -A`
2. Create LimitRanges in application namespaces to set default requests and limits for CPU and memory.
3. Apply through templates or GitOps for consistency.
   `oc apply -f <limitrange.yaml> -n <ns>`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

namespace admission defaults

impact_detail SHALL be:

LimitRanges affect new or updated pods by applying default requests and limits; existing pods continue running unchanged.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`.

#### Scenario: 7.6.limitranges loads
- WHEN `get_entry` is called with `7.6.limitranges`
- THEN the title is `LimitRanges`
- AND `content_from` is empty


### Requirement: KB 7.6.op_approval
`load_kb()` SHALL contain `7.6.op_approval` from `7_6_day2.toml`. Title SHALL be `Operator approval policy`.

`content_from` SHALL be `7.1.subs.approval` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.op_approval loads
- WHEN `get_entry` is called with `7.6.op_approval`
- THEN the title is `Operator approval policy`
- AND `content_from` is `7.1.subs.approval`


### Requirement: KB 7.6.deploymentconfigs
`load_kb()` SHALL contain `7.6.deploymentconfigs` from `7_6_day2.toml`. Title SHALL be `DeploymentConfigs`.

description SHALL be:

DeploymentConfig resources are deprecated and should be migrated to Kubernetes
Deployments for long-term supportability.

recommendation SHALL be:

Rewrite DeploymentConfigs to Kubernetes Deployments and map image-change triggers to CI. Inventory replicas and strategy first. Do not dump every DC YAML.

verification SHALL be:

1. List all DeploymentConfigs with namespace, name, replicas, and strategy. Any row is a deprecated resource to migrate.
   `oc get dc -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,REPLICAS:.spec.replicas,STRATEGY:.spec.strategy.type`
2. For a single DeploymentConfig, print strategy and replica count.
   `oc get dc <name> -n <ns> -o jsonpath='{.spec.strategy.type}{" "}{.spec.replicas}{"\n"}'`
3. Migrate each DeploymentConfig to a Kubernetes Deployment because the API is deprecated.
4. Rewrite manifests using the Deployment API, mapping triggers to image-change annotations or CI/CD pipelines.

impact SHALL be:

workload-shift

impact_scope SHALL be:

migrated application workloads

impact_detail SHALL be:

Cutting over from DeploymentConfig to Deployment triggers an application rollout and may reschedule or restart pods during migration.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/building_applications/index#deployments-comparing-deploymentconfigs_what-deployments-are`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/building_applications/index#deployments-comparing-deploymentconfigs_what-deployments-are`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/building_applications/index#deployments-comparing-deploymentconfigs_what-deployments-are`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/building_applications/index#deployments-comparing-deploymentconfigs_what-deployments-are`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/building_applications/index#deployments-comparing-deploymentconfigs_what-deployments-are`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/building_applications/index#deployments-comparing-deploymentconfigs_what-deployments-are`.

#### Scenario: 7.6.deploymentconfigs loads
- WHEN `get_entry` is called with `7.6.deploymentconfigs`
- THEN the title is `DeploymentConfigs`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_1_1_quota_resources_project_assignment
`load_kb()` SHALL contain `7.6.tsr.6_1_1_1_quota_resources_project_assignment` from `7_6_day2.toml`. Title SHALL be `TSR quota resources project assignment`.

description SHALL be:

This check identifies projects with no ResourceQuota or LimitRange. Without quotas, a namespace can consume unbounded CPU, memory, and storage. This is a project-admission finding, not a statement about VM template defaults.

recommendation SHALL be:

Define a ResourceQuota and, where appropriate, a LimitRange for application and user-managed projects that run workloads to establish enforceable CPU, memory, and object-consumption boundaries. Size quotas using observed workload requests, limits, storage requirements, expected growth, and VM resource profiles so that the controls prevent uncontrolled consumption without blocking legitimate deployments.

verification SHALL be:

1. List ResourceQuota across all namespaces (first column is the namespace).
   `oc get resourcequota -A`
2. List LimitRange across all namespaces.
   `oc get limitrange -A`
3. Find user projects with no quota or limit coverage. **FAIL** for each uncovered project; **PASS** if all user projects are covered. Platform namespaces (openshift-*, kube-*, default, openshift) are skipped.
   `comm -23 <(oc get ns --no-headers -o custom-columns=NS:.metadata.name | awk '$1 !~ /^(openshift-|kube-)/ && $1 != "openshift" && $1 != "default"' | sort) <({ oc get resourcequota -A --no-headers; oc get limitrange -A --no-headers; } 2>/dev/null | awk 'NF{print $1}' | sort -u) | awk '{print "FAIL NS="$1} END{if(NR==0) print "PASS none-uncovered"}'`
4. On **FAIL**, create a ResourceQuota sized to that project.
   `oc create quota compute --hard=requests.cpu=8,requests.memory=16Gi,pods=25 -n <ns> --dry-run=client -o name`
5. Print the project-request template. If the template is missing, the command prints **INFO** — that is not a **FAIL**.
   `oc get template project-request -n openshift-config 2>&1 | awk '/NotFound|No resources found/{print "INFO n/a-project-request"; n=1; next} {print} END{if(!n && NR==0) print "INFO n/a-project-request"}'`
Missing `project-request` is **INFO**, not a **FAIL**. Drop `--dry-run=client` to apply.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

namespace admission and capacity guardrails

impact_detail SHALL be:

ResourceQuota changes affect future creates and scale-outs but do not restart nodes or terminate running workloads.

priority_hint SHALL be:

P3

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/building_applications/index#quotas-creating-a-quota_quotas-setting-per-project`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/building_applications/index#quotas-creating-a-quota_quotas-setting-per-project`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/building_applications/index#quotas-creating-a-quota_quotas-setting-per-project`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/building_applications/index#quotas-creating-a-quota_quotas-setting-per-project`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/building_applications/index#quotas-creating-a-quota_quotas-setting-per-project`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/building_applications/index#quotas-creating-a-quota_quotas-setting-per-project`.

A summary pattern containing `no quota nor limits` SHALL produce `One or more projects have no ResourceQuota or LimitRange.`.

#### Scenario: 7.6.tsr.6_1_1_1_quota_resources_project_assignment loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_1_1_quota_resources_project_assignment`
- THEN the title is `TSR quota resources project assignment`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_5_5_node_garbage_collection
`load_kb()` SHALL contain `7.6.tsr.6_1_5_5_node_garbage_collection` from `7_6_day2.toml`. Title SHALL be `TSR node garbage collection`.

description SHALL be:

This check evaluates how full the image filesystem is on each node compared with kubelet image garbage-collection thresholds. OpenShift defaults the high threshold to 85 percent and the low threshold to 80 percent. Image use above half of that filesystem is an early warning; kubelet garbage collection still starts at the applied high threshold.

recommendation SHALL be:

When images use more than half of the node image filesystem, prune unused images, reduce image churn, or grow the disk. Do not raise the kubelet high garbage-collection threshold to silence that early warning. Kubelet still starts garbage collection at the applied high threshold (default 85 percent), not at 50 percent.

verification SHALL be:

1. Print image filesystem fill against the applied garbage-collection HIGH threshold per node. **FAIL** if USED% is at or above HIGH; **PASS** otherwise. HIGH defaults to 85 when no `KubeletConfig` overrides it.
   `oc get nodes --no-headers -o custom-columns=NAME:.metadata.name | while read -r node; do high=$(oc get --raw /api/v1/nodes/${node}/proxy/configz | jq -r '.kubeletconfig.imageGCHighThresholdPercent // 85'); oc get --raw /api/v1/nodes/${node}/proxy/stats/summary | jq -r --arg node "$node" --arg high "$high" '(.node.runtime.imageFs // .node.fs) as $fs | [$node, $high, $fs.capacityBytes, $fs.availableBytes] | @tsv'; done | awk '{used=int(($3-$4)*100/$3); r="PASS"; if(used>=$2+0) r="FAIL"; print r, "NODE="$1, "USED="used"%", "HIGH="$2}'`
2. Print the same image filesystem USED% against the TSR early-warning bar. **WARNING** if USED% is at least 50 and still below HIGH; **PASS** if USED% is under 50; **FAIL** if USED% is at or above HIGH.
   `oc get nodes --no-headers -o custom-columns=NAME:.metadata.name | while read -r node; do high=$(oc get --raw /api/v1/nodes/${node}/proxy/configz | jq -r '.kubeletconfig.imageGCHighThresholdPercent // 85'); oc get --raw /api/v1/nodes/${node}/proxy/stats/summary | jq -r --arg node "$node" --arg high "$high" '(.node.runtime.imageFs // .node.fs) as $fs | [$node, $high, $fs.capacityBytes, $fs.availableBytes] | @tsv'; done | awk '{used=int(($3-$4)*100/$3); r="PASS"; if(used>=$2+0) r="FAIL"; else if(used>=50) r="WARNING"; print r, "NODE="$1, "USED="used"%", "HIGH="$2, "TSR50=50"}'`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the targeted MachineConfigPool

impact_detail SHALL be:

Changing kubelet garbage-collection settings through `KubeletConfig` or MachineConfig drains and reboots affected nodes one at a time.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-garbage-collection-configuring_nodes-nodes-configuring`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-nodes-garbage-collection-configuring_nodes-nodes-configuring`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-nodes-garbage-collection-configuring_nodes-nodes-configuring`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-nodes-garbage-collection-configuring_nodes-nodes-configuring`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-nodes-garbage-collection-configuring_nodes-nodes-configuring`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-nodes-garbage-collection-configuring_nodes-nodes-configuring`.

A summary pattern containing `more than half of the total disk` SHALL produce `TSR: images already use more than half of node disk (early warning; kubelet GC default is 85%).`.

#### Scenario: 7.6.tsr.6_1_5_5_node_garbage_collection loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_5_5_node_garbage_collection`
- THEN the title is `TSR node garbage collection`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_2_1_update_history
`load_kb()` SHALL contain `7.6.tsr.6_2_1_update_history` from `7_6_day2.toml`. Title SHALL be `TSR update history`.

description SHALL be:

This check reviews the cluster's upgrade history to identify how current the cluster version is and whether any previous upgrades failed. Clusters that fall behind on updates accumulate known security vulnerabilities and may face more complex upgrade paths to catch up.

recommendation SHALL be:

Keep the cluster current on a hop the Upgrade Graph allows; do not jump a minor the graph does not allow. Test in non-production first. A failed previous upgrade must be resolved before the next hop.

verification SHALL be:

1. Print the cluster upgrade history versions. Review whether the cluster is current or lagging behind.
   `oc get clusterversion -o jsonpath='{.items[0].status.history[*].version}'`
2. Check available update paths using the OCP Upgrade Graph:
      https://access.redhat.com/labs/ocpupgradegraph/
3. For clusters multiple minor versions behind, follow the supported upgrade path (direct jumps may not be available).
4. Always test the upgrade in a non-production cluster first.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster-wide

impact_detail SHALL be:

Remediating stale update history usually means performing one or more supported cluster upgrades, which roll operators, nodes, and workloads over time.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#gathering-clusterversion-history-cli_troubleshooting_updates`.

#### Scenario: 7.6.tsr.6_2_1_update_history loads
- WHEN `get_entry` is called with `7.6.tsr.6_2_1_update_history`
- THEN the title is `TSR update history`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_3_1_current_node_load
`load_kb()` SHALL contain `7.6.tsr.6_1_3_1_current_node_load` from `7_6_day2.toml`. Title SHALL be `TSR current node load`.

description SHALL be:

Sustained high CPU or memory utilization on nodes indicates capacity pressure.
Overloaded nodes experience scheduling delays, OOMKills, and potential workload
eviction during spikes.

recommendation SHALL be:

Add workers, spread load, or right-size requests when `oc adm top` shows nodes consistently above about 80% CPU or memory. That is usage, not requests.

verification SHALL be:

1. Print node CPU and memory utilization. Nodes consistently above 80% need attention.
   `oc adm top nodes`
2. Scale by adding workers, rebalance with pod anti-affinity or topology-spread constraints, or right-size pod resource requests.

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads on nodes above about 80% CPU or memory

impact_detail SHALL be:

Spreading load or right-sizing requests reschedules those pods. Adding workers is a maintenance window.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-viewing-memory_nodes-nodes-viewing`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-nodes-viewing-memory_nodes-nodes-viewing`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-nodes-viewing-memory_nodes-nodes-viewing`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-nodes-viewing-memory_nodes-nodes-viewing`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-nodes-viewing-memory_nodes-nodes-viewing`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-nodes-viewing-memory_nodes-nodes-viewing`.

#### Scenario: 7.6.tsr.6_1_3_1_current_node_load loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_3_1_current_node_load`
- THEN the title is `TSR current node load`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_5_1_pod_pruning
`load_kb()` SHALL contain `7.6.tsr.6_1_5_1_pod_pruning` from `7_6_day2.toml`. Title SHALL be `TSR pod pruning`.

`content_from` SHALL be `7.5.pruning.pods` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.tsr.6_1_5_1_pod_pruning loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_5_1_pod_pruning`
- THEN the title is `TSR pod pruning`
- AND `content_from` is `7.5.pruning.pods`


### Requirement: KB 7.6.tsr.6_1_5_4_job_pruning
`load_kb()` SHALL contain `7.6.tsr.6_1_5_4_job_pruning` from `7_6_day2.toml`. Title SHALL be `TSR job pruning`.

`content_from` SHALL be `7.5.pruning.jobs` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.tsr.6_1_5_4_job_pruning loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_5_4_job_pruning`
- THEN the title is `TSR job pruning`
- AND `content_from` is `7.5.pruning.jobs`


### Requirement: KB 7.6.tsr.6_3_1_active_alerts
`load_kb()` SHALL contain `7.6.tsr.6_3_1_active_alerts` from `7_6_day2.toml`. Title SHALL be `TSR active alerts`.

`content_from` SHALL be `7.5.tsr.5_11_health_related_alerts` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.tsr.6_3_1_active_alerts loads
- WHEN `get_entry` is called with `7.6.tsr.6_3_1_active_alerts`
- THEN the title is `TSR active alerts`
- AND `content_from` is `7.5.tsr.5_11_health_related_alerts`


### Requirement: KB 7.6.storage.default_sc
`load_kb()` SHALL contain `7.6.storage.default_sc` from `7_6_day2.toml`. Title SHALL be `Default storage class`.

`content_from` SHALL be `7.3.storage.default_sc` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.storage.default_sc loads
- WHEN `get_entry` is called with `7.6.storage.default_sc`
- THEN the title is `Default storage class`
- AND `content_from` is `7.3.storage.default_sc`


### Requirement: KB 7.6.storage.pvcs
`load_kb()` SHALL contain `7.6.storage.pvcs` from `7_6_day2.toml`. Title SHALL be `Persistent volume claims`.

`content_from` SHALL be `7.3.storage.pvcs` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.storage.pvcs loads
- WHEN `get_entry` is called with `7.6.storage.pvcs`
- THEN the title is `Persistent volume claims`
- AND `content_from` is `7.3.storage.pvcs`


### Requirement: KB 7.6.tsr.6_1_capacity_management
`load_kb()` SHALL contain `7.6.tsr.6_1_capacity_management` from `7_6_day2.toml`. Title SHALL be `6.1. Capacity Management`.

description SHALL be:

Parent section covering cluster capacity management including quotas, resource
requests and limits, node load, persistent volume usage, pruning, infra node
workloads, and liveness probe configuration.

recommendation SHALL be:

This section is capacity posture. Scored recs live on the children: quota, requests and limits, node load, persistent-volume usage, and pruning.

verification SHALL be:

1. Print node capacity utilization.
   `oc adm top nodes`
2. List ResourceQuota coverage across namespaces.
   `oc get resourcequota -A`
3. List LimitRange coverage across namespaces.
   `oc get limitrange -A`
4. List persistent volumes and their status.
   `oc get pv`
5. Address individual sub-check findings for specific capacity concerns.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#compute-resource-quotas`.

#### Scenario: 7.6.tsr.6_1_capacity_management loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_capacity_management`
- THEN the title is `6.1. Capacity Management`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_1_quota_and_resources
`load_kb()` SHALL contain `7.6.tsr.6_1_1_quota_and_resources` from `7_6_day2.toml`. Title SHALL be `6.1.1. Quota and Resources`.

description SHALL be:

Evaluates ResourceQuota and LimitRange coverage across namespaces. Without
quotas, individual namespaces can exhaust shared cluster capacity and create
noisy-neighbor conditions for other tenants.

recommendation SHALL be:

This section is ResourceQuota and LimitRange coverage on tenant projects. Scored recommendations live on project assignment and cluster-quota configuration children.

verification SHALL be:

1. List ResourceQuota coverage across namespaces.
   `oc get resourcequota -A`
2. Print LimitRange defaults (DEFAULT_CPU, DEFAULT_MEM) per namespace.
   `oc get limitrange -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,DEFAULT_CPU:.spec.limits[0].default.cpu,DEFAULT_MEM:.spec.limits[0].default.memory`
3. Apply ResourceQuotas to tenant namespaces.
4. Configure project templates to auto-apply quotas on namespace creation.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

namespace admission and capacity guardrails

impact_detail SHALL be:

Quota changes take effect immediately for new creates and scale-outs but do not restart nodes or stop running workloads.

priority_hint SHALL be:

P3

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#compute-resource-quotas`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#compute-resource-quotas`.

#### Scenario: 7.6.tsr.6_1_1_quota_and_resources loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_1_quota_and_resources`
- THEN the title is `6.1.1. Quota and Resources`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_1_2_cluster_quota_configuration
`load_kb()` SHALL contain `7.6.tsr.6_1_1_2_cluster_quota_configuration` from `7_6_day2.toml`. Title SHALL be `6.1.1.2. Cluster Quota Configuration`.

description SHALL be:

This check evaluates ClusterResourceQuota objects, which enforce a shared resource limit across multiple OpenShift namespaces selected by project labels or annotations. Unlike a namespace-scoped ResourceQuota, usage is aggregated across all matching projects, so an incorrect selector or undersized hard limit can block workload creation or scaling in multiple namespaces.

recommendation SHALL be:

Keep each ClusterResourceQuota selector narrowly scoped to the intended projects and size its hard limits for the combined CPU, memory, storage, pod, and object capacity those projects are allowed to consume. Review aggregate used versus hard before onboarding namespaces or scaling workloads. An empty selector, no matching namespaces, or no ClusterResourceQuota is not inherently unhealthy. It may simply mean no shared cross-project cap is intended.

verification SHALL be:

1. List ClusterResourceQuota objects with their selectors and hard limits.
   `oc get clusterresourcequota -o custom-columns=NAME:.metadata.name,SELECTOR:.spec.selector,HARD:.spec.quota.hard`
2. Check actual consumption against limits for a specific quota.
   `oc describe clusterresourcequota <name>`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

cross-namespace resource admission

impact_detail SHALL be:

ClusterResourceQuota changes affect admission for new creates across selected namespaces without restarting nodes.

priority_hint SHALL be:

P3

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#quota-scopes_using-quotas-and-limit-ranges`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#quota-scopes_using-quotas-and-limit-ranges`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#quota-scopes_using-quotas-and-limit-ranges`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#quota-scopes_using-quotas-and-limit-ranges`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#quota-scopes_using-quotas-and-limit-ranges`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#quota-scopes_using-quotas-and-limit-ranges`.

#### Scenario: 7.6.tsr.6_1_1_2_cluster_quota_configuration loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_1_2_cluster_quota_configuration`
- THEN the title is `6.1.1.2. Cluster Quota Configuration`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_2_requests_and_limits
`load_kb()` SHALL contain `7.6.tsr.6_1_2_requests_and_limits` from `7_6_day2.toml`. Title SHALL be `6.1.2. Requests and Limits`.

description SHALL be:

Checks that pods specify CPU and memory requests and limits. Pods without
requests cannot be effectively scheduled; pods without limits risk consuming
unbounded resources and causing OOMKills on co-located workloads.

recommendation SHALL be:

Set realistic CPU and memory requests for all production pods, then add limits where appropriate. Requests allow the scheduler to reserve capacity; pods with no CPU or memory requests are **BestEffort** and are first to be evicted during node resource pressure. Use a namespace LimitRange to apply safe default requests and limits where application manifests omit them, then review and tune those defaults against observed utilization to avoid under-sizing workloads or overcommitting nodes.

verification SHALL be:

1. List pods with missing CPU or memory requests. Any printed row is a pod without requests — it runs as **BestEffort** and is first to evict.
   `oc get pods -A --no-headers -o custom-columns=NS:.metadata.namespace,POD:.metadata.name,CPU:.spec.containers[*].resources.requests.cpu,MEM:.spec.containers[*].resources.requests.memory | awk '$3=="<none>" || $4=="<none>" {print}'`
2. Apply LimitRanges to set defaults.
3. Enforce minimum and maximum resource boundaries per container in each namespace.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

namespace admission defaults

impact_detail SHALL be:

LimitRange enforcement applies to new or updated pods; existing pods continue running unchanged.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/scalability_and_performance/index#admin-quota-limits_using-quotas-and-limit-ranges`.

#### Scenario: 7.6.tsr.6_1_2_requests_and_limits loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_2_requests_and_limits`
- THEN the title is `6.1.2. Requests and Limits`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_3_node_load
`load_kb()` SHALL contain `7.6.tsr.6_1_3_node_load` from `7_6_day2.toml`. Title SHALL be `6.1.3. Node Load`.

`content_from` SHALL be `7.6.tsr.6_1_3_1_current_node_load` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.tsr.6_1_3_node_load loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_3_node_load`
- THEN the title is `6.1.3. Node Load`
- AND `content_from` is `7.6.tsr.6_1_3_1_current_node_load`


### Requirement: KB 7.6.tsr.6_1_3_2_node_expected_resource_consumption
`load_kb()` SHALL contain `7.6.tsr.6_1_3_2_node_expected_resource_consumption` from `7_6_day2.toml`. Title SHALL be `6.1.3.2. Node Expected Resource Consumption`.

description SHALL be:

The TSR compares current pod requests to a per-node expected max-usage (Limits) percent it computed. Those percents differ by node (examples 2%/1% or 10%/2% in other dumps). This is not the request/allocatable overcommit check (> 1.0).

recommendation SHALL be:

On TSR FAIL or WARNING, right-size requests and limits or add capacity on that node. Do not use `oc adm top` as the TSR bar. Do not apply a single cluster-wide percent.

verification SHALL be:

1. The scored bar is in the TSR Result text (`expected is cpu:… ram:… while currently requests …`). Read that remainder; this step does not invent a PASS/FAIL percent.
2. Optional live context only: print Allocated resources on a named node. This is **INFO**, not PASS/FAIL against TSR percents.
   `oc describe node <name>`

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads on the FAIL or WARNING node

impact_detail SHALL be:

Right-sizing requests and limits or adding capacity reschedules those pods. Do not use oc adm top as the TSR bar.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/nodes/index#nodes-cluster-overcommit-reserving-resources_nodes-cluster-overcommit`.

#### Scenario: 7.6.tsr.6_1_3_2_node_expected_resource_consumption loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_3_2_node_expected_resource_consumption`
- THEN the title is `6.1.3.2. Node Expected Resource Consumption`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_4_persistent_volume_usage
`load_kb()` SHALL contain `7.6.tsr.6_1_4_persistent_volume_usage` from `7_6_day2.toml`. Title SHALL be `6.1.4. Persistent Volume Usage`.

description SHALL be:

Monitors PersistentVolume capacity utilization and identifies volumes at risk
of exhaustion. Full PVs cause application write failures, pod crashes, and
potential data loss.

recommendation SHALL be:

Grow or replace volumes before kubelet USED% and KubePersistentVolumeFillingUp cross about 90% used, and plan ahead once they pass 75%. This is filesystem fill, not `oc adm top`. `EXPAND=true` can grow in place; `EXPAND=false` needs a larger volume or a new PVC.

verification SHALL be:

1. Print PVC USED% from kubelet volume stats via Prometheus. **FAIL** if above 90%; **WARNING** if above 75%; **PASS** otherwise. If no PVCs report data, the command prints **INFO**.
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * 100' | jq -r '.data.result[] | [.metric.namespace, .metric.persistentvolumeclaim, .value[1]] | @tsv' | awk -F'\t' '{pct=$3+0; r="PASS"; if(pct>90) r="FAIL"; else if(pct>75) r="WARNING"; print r, "NS="$1, "PVC="$2, "USED="int(pct)"%"} END{if(NR==0) print "INFO n/a-pvc-util"}'`
2. Print firing KubePersistentVolumeFillingUp alerts. **FAIL** for each listed row. If no alerts are firing, the command prints **INFO**.
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | select(.labels.alertname=="KubePersistentVolumeFillingUp") | [.state, .labels.namespace, .labels.persistentvolumeclaim, .labels.severity] | @tsv' | awk -F'\t' '{print "FAIL", "STATE="$1, "NS="$2, "PVC="$3, "SEVERITY="$4} END{if(NR==0) print "INFO n/a-fillingup-alert"}'`
3. Print StorageClass volume expansion support. **FAIL** or **WARNING** PVCs with `EXPAND=true` can grow in place; `EXPAND=false` needs a new, larger volume.
   `oc get sc -o custom-columns=NAME:.metadata.name,EXPAND:.allowVolumeExpansion --no-headers | awk '{print "NAME="$1, "EXPAND="$2}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads mounted to the affected PVC

impact_detail SHALL be:

Online expansion may be transparent, but storage migration or cutover can require pod restart, rescheduling, or temporary workload movement.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#expanding-pvc_expanding-persistent-volumes`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#expanding-pvc_expanding-persistent-volumes`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#expanding-pvc_expanding-persistent-volumes`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#expanding-pvc_expanding-persistent-volumes`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#expanding-pvc_expanding-persistent-volumes`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#expanding-pvc_expanding-persistent-volumes`.

#### Scenario: 7.6.tsr.6_1_4_persistent_volume_usage loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_4_persistent_volume_usage`
- THEN the title is `6.1.4. Persistent Volume Usage`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_5_pruning
`load_kb()` SHALL contain `7.6.tsr.6_1_5_pruning` from `7_6_day2.toml`. Title SHALL be `6.1.5. Pruning`.

`content_from` SHALL be `7.5.pruning.pods` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.tsr.6_1_5_pruning loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_5_pruning`
- THEN the title is `6.1.5. Pruning`
- AND `content_from` is `7.5.pruning.pods`


### Requirement: KB 7.6.tsr.6_1_5_2_build_pruning
`load_kb()` SHALL contain `7.6.tsr.6_1_5_2_build_pruning` from `7_6_day2.toml`. Title SHALL be `6.1.5.2. Build Pruning`.

description SHALL be:

Evaluates build history retention settings. Accumulated completed and failed
builds consume etcd storage and slow BuildConfig list operations without
providing operational value.

recommendation SHALL be:

Cap `successfulBuildsHistoryLimit` and `failedBuildsHistoryLimit` so completed Builds age out of etcd. Delete stale completed builds only after you confirm they are not needed.

verification SHALL be:

1. List builds sorted by creation time. Large accumulations indicate missing pruning.
   `oc get builds -A --sort-by=.metadata.creationTimestamp`
2. Configure pruning on each BuildConfig with `successfulBuildsHistoryLimit` and `failedBuildsHistoryLimit`.
3. Clean up stale completed builds in namespaces with excessive build history.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

completed build object retention

impact_detail SHALL be:

Build history-limit settings affect future cleanup behavior without restarting nodes or interrupting running builds.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/builds_using_buildconfig/index#builds-build-pruning_build-configuration`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/builds_using_buildconfig/index#builds-build-pruning_build-configuration`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/builds_using_buildconfig/index#builds-build-pruning_build-configuration`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/builds_using_buildconfig/index#builds-build-pruning_build-configuration`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/builds_using_buildconfig/index#builds-build-pruning_build-configuration`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/builds_using_buildconfig/index#builds-build-pruning_build-configuration`.

#### Scenario: 7.6.tsr.6_1_5_2_build_pruning loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_5_2_build_pruning`
- THEN the title is `6.1.5.2. Build Pruning`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_5_3_network_policy_pruning
`load_kb()` SHALL contain `7.6.tsr.6_1_5_3_network_policy_pruning` from `7_6_day2.toml`. Title SHALL be `6.1.5.3. Network Policy Pruning`.

description SHALL be:

Identifies orphaned or redundant NetworkPolicies that no longer match any pods.
Stale policies add OVN/iptables processing overhead and complicate security
auditing without providing effective segmentation.

recommendation SHALL be:

Remove user NetworkPolicies whose selector matches zero pods. `POD-SELECTOR <none>` means all pods in the namespace (often default-deny), not an orphan. Skip platform namespaces.

verification SHALL be:

1. List user-namespace NetworkPolicies, skipping openshift-*, kube-*, default, and openshift. A POD-SELECTOR of <none> means all pods (usually default-deny) — not orphaned. If no user-namespace policies exist, the command prints **INFO**.
   `oc get networkpolicy -A | awk 'NR==1{hdr=$0; next} $1 ~ /^(openshift-|kube-)/ || $1=="openshift" || $1=="default" {next} {if(!c) print hdr; print; c++} END{if(!c) print "INFO n/a-user-netpol"}'`
2. For a policy with a label POD-SELECTOR, count matching pods. **FAIL** if `MATCH=0`; **PASS** otherwise.
   `oc get pods -n <ns> -l '<POD-SELECTOR>' --no-headers | awk 'END{c=NR; r=(c==0?"FAIL":"PASS"); print r, "MATCH="c}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

network policy rule tables

impact_detail SHALL be:

Removing unused NetworkPolicies updates OVN/iptables rules without disrupting existing pod connectivity.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/network_security/index#about-network-policy`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/network_security/index#about-network-policy`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/network_security/index#about-network-policy`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/network_security/index#about-network-policy`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/network_security/index#about-network-policy`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/network_security/index#about-network-policy`.

#### Scenario: 7.6.tsr.6_1_5_3_network_policy_pruning loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_5_3_network_policy_pruning`
- THEN the title is `6.1.5.3. Network Policy Pruning`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_5_6_pruning_namespaces
`load_kb()` SHALL contain `7.6.tsr.6_1_5_6_pruning_namespaces` from `7_6_day2.toml`. Title SHALL be `6.1.5.6. Pruning Namespaces`.

`content_from` SHALL be `7.6.namespaces` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.tsr.6_1_5_6_pruning_namespaces loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_5_6_pruning_namespaces`
- THEN the title is `6.1.5.6. Pruning Namespaces`
- AND `content_from` is `7.6.namespaces`


### Requirement: KB 7.6.tsr.6_1_6_infra_node_workloads
`load_kb()` SHALL contain `7.6.tsr.6_1_6_infra_node_workloads` from `7_6_day2.toml`. Title SHALL be `6.1.6. Infra Node Workloads`.

description SHALL be:

Validates that infrastructure workloads (monitoring, logging, ingress routers)
are scheduled on dedicated infra nodes rather than worker nodes. Proper
placement avoids subscription cost for infra workloads and isolates platform
services from application resource contention.

recommendation SHALL be:

If the design uses dedicated infra nodes, set nodeSelectors and tolerations on the operator CRs, not on individual pods. Missing labels on compact and SNO are expected — those clusters have no spare infra.

verification SHALL be:

1. List nodes with the infra role label. An empty result means no dedicated infra nodes exist.
   `oc get nodes -l node-role.kubernetes.io/infra=`
2. Check that monitoring pods are scheduled on infra nodes.
   `oc get pods -n openshift-monitoring -o wide`
3. Check that router pods are scheduled on infra nodes.
   `oc get pods -n openshift-ingress -o wide`
4. Configure nodeSelectors and tolerations in the respective operator CRs to target infra nodes.

impact SHALL be:

workload-shift

impact_scope SHALL be:

infra workload pod scheduling

impact_detail SHALL be:

Moving infra workloads to dedicated nodes causes pod rescheduling and brief interruptions to monitoring or ingress during migration.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_management/index#creating-infrastructure-machinesets`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_management/index#creating-infrastructure-machinesets`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/machine_management/index#creating-infrastructure-machinesets`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/machine_management/index#creating-infrastructure-machinesets`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/machine_management/index#creating-infrastructure-machinesets`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/machine_management/index#creating-infrastructure-machinesets`.

#### Scenario: 7.6.tsr.6_1_6_infra_node_workloads loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_6_infra_node_workloads`
- THEN the title is `6.1.6. Infra Node Workloads`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_1_7_liveness_probes
`load_kb()` SHALL contain `7.6.tsr.6_1_7_liveness_probes` from `7_6_day2.toml`. Title SHALL be `6.1.7. Liveness Probes`.

description SHALL be:

Evaluates liveness probe configuration across workloads. Missing or
misconfigured liveness probes prevent kubelet from detecting and restarting
hung containers, while overly aggressive probes cause unnecessary restarts.

recommendation SHALL be:

Maintain liveness probes for workloads where a running but hung container must be restarted automatically. Tune probe paths, commands, timeouts, failure thresholds, and startup delays to reflect actual application behavior. Use a `startupProbe` for slow-starting applications so liveness checks do not cause restart loops.

verification SHALL be:

1. List pods whose LIVENESS column is <none>, meaning no liveness probe is configured.
   `oc get pods -A --no-headers -o custom-columns=NS:.metadata.namespace,POD:.metadata.name,LIVENESS:.spec.containers[*].livenessProbe | awk '$3=="<none>" {print}'`
2. Review probe timeouts and thresholds on frequently restarting pods.
3. Ensure probes are not too aggressive for the application startup time.

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads whose probe spec changes

impact_detail SHALL be:

Adding or retuning liveness or startup probes rolls those containers if the probe fails during rollout.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/building_applications/index#application-health`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/building_applications/index#application-health`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/building_applications/index#application-health`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/building_applications/index#application-health`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/building_applications/index#application-health`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/building_applications/index#application-health`.

#### Scenario: 7.6.tsr.6_1_7_liveness_probes loads
- WHEN `get_entry` is called with `7.6.tsr.6_1_7_liveness_probes`
- THEN the title is `6.1.7. Liveness Probes`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_2_patch_management
`load_kb()` SHALL contain `7.6.tsr.6_2_patch_management` from `7_6_day2.toml`. Title SHALL be `6.2. Patch Management`.

description SHALL be:

Parent section covering cluster and workload patching including update history,
workload impact assessment, and container image currency. Stale patches
increase security exposure and supportability risk.

recommendation SHALL be:

This section is whether the cluster and its operators can still patch. Scored recs live on the children: update history, update-impacting workloads, and image patch policy.

verification SHALL be:

1. Print the current cluster version and update channel, then list available upgrades.
   `oc get clusterversion version -o jsonpath='{.status.desired.version}{" "}{.spec.channel}{"\n"}'`
   `oc adm upgrade`
2. List operator subscriptions where INSTALLED differs from CURRENT, indicating a pending update.
   `oc get subscription -A --no-headers -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,INSTALLED:.status.installedCSV,CURRENT:.status.currentCSV | awk '$3!=$4 {print}'`
3. Plan upgrade paths using the OCP Upgrade Graph.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#understanding-openshift-updates`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#understanding-openshift-updates`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#understanding-openshift-updates`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#understanding-openshift-updates`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#understanding-openshift-updates`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#understanding-openshift-updates`.

#### Scenario: 7.6.tsr.6_2_patch_management loads
- WHEN `get_entry` is called with `7.6.tsr.6_2_patch_management`
- THEN the title is `6.2. Patch Management`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_2_2_update_impacting_workloads
`load_kb()` SHALL contain `7.6.tsr.6_2_2_update_impacting_workloads` from `7_6_day2.toml`. Title SHALL be `6.2.2. Update Impacting Workloads`.

description SHALL be:

This check is user-namespace Deployments with `REPLICAS=1`. Those pods go down when a node drains during an upgrade. Skip openshift-* kube-* default and openshift.

recommendation SHALL be:

Raise replicas or add a PDB that still allows a drain on user-namespace Deployments with `REPLICAS=1`. Leaving `REPLICAS=1` is accepted risk only if that downtime is documented.

verification SHALL be:

1. List user-namespace Deployments with `REPLICAS=1`, skipping openshift-*, kube-*, default, and openshift. **WARNING** for each single-replica Deployment; **PASS** if none are found.
   `oc get deploy -A --no-headers -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,REPLICAS:.spec.replicas | awk '$1 ~ /^(openshift-|kube-)/ || $1=="openshift" || $1=="default" {next} $3=="1"{print "WARNING", "NS="$1, "NAME="$2, "REPLICAS="$3; c++} END{if(!c) print "PASS none-single-replica"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

user-namespace Deployments with REPLICAS=1

impact_detail SHALL be:

Raising replicas rolls a second pod. A PDB that still allows drain changes eviction behavior without stopping already-running pods.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#understanding-openshift-updates`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#understanding-openshift-updates`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#understanding-openshift-updates`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#understanding-openshift-updates`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#understanding-openshift-updates`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#understanding-openshift-updates`.

#### Scenario: 7.6.tsr.6_2_2_update_impacting_workloads loads
- WHEN `get_entry` is called with `7.6.tsr.6_2_2_update_impacting_workloads`
- THEN the title is `6.2.2. Update Impacting Workloads`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_2_3_images_patch_management
`load_kb()` SHALL contain `7.6.tsr.6_2_3_images_patch_management` from `7_6_day2.toml`. Title SHALL be `6.2.3. Images Patch Management`.

description SHALL be:

This check reviews the cluster Image configuration’s `registrySources` policy: `allowedRegistries`, `blockedRegistries`, and `insecureRegistries`. These settings control which external registries nodes may use for image pulls and pushes; they do not govern the internal OpenShift image registry. `allowedRegistries` permits only listed registries, while `blockedRegistries` denies listed registries. These two settings are mutually exclusive. An empty configuration is the normal connected-cluster default.

recommendation SHALL be:

Keep registry-source settings aligned with the approved image supply chain policy. Use an allowlist where registry access must be tightly controlled, or a blocklist for specific prohibited sources—never configure both. When using an allowlist, include all registries required for platform updates, Operators, workloads, and the internal registry as applicable. Avoid `insecureRegistries` whenever possible.

verification SHALL be:

1. Print allowed registries from image.config. An empty list is **INFO** (the connected-cluster default).
   `oc get image.config cluster -o json | jq -r '(.spec.registrySources.allowedRegistries | if type=="array" then . else [] end)[]' | awk 'NF{print "INFO", "ALLOWED="$0; c++} END{if(!c) print "INFO none-allowed"}'`
2. Print blocked registries. An empty list is **INFO**.
   `oc get image.config cluster -o json | jq -r '(.spec.registrySources.blockedRegistries | if type=="array" then . else [] end)[]' | awk 'NF{print "INFO", "BLOCKED="$0; c++} END{if(!c) print "INFO none-blocked"}'`
3. Print insecure registries. **WARNING** for each listed row; **PASS** if the list is empty.
   `oc get image.config cluster -o json | jq -r '(.spec.registrySources.insecureRegistries | if type=="array" then . else [] end)[]' | awk 'NF{print "WARNING", "INSECURE="$0; c++} END{if(!c) print "PASS none-insecure"}'`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes via image.config and CRI-O policy

impact_detail SHALL be:

allowedRegistries or a blocklist on the cluster Image CR typically rolls kubelet and CRI-O through the Machine Config Operator.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/images/index#images-configuration-registry-mirror-images-configuration`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/images/index#images-configuration-registry-mirror-images-configuration`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/images/index#images-configuration-registry-mirror-images-configuration`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/images/index#images-configuration-registry-mirror-images-configuration`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/images/index#images-configuration-registry-mirror-images-configuration`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/images/index#images-configuration-registry-mirror-images-configuration`.

#### Scenario: 7.6.tsr.6_2_3_images_patch_management loads
- WHEN `get_entry` is called with `7.6.tsr.6_2_3_images_patch_management`
- THEN the title is `6.2.3. Images Patch Management`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_3_alert_management
`load_kb()` SHALL contain `7.6.tsr.6_3_alert_management` from `7_6_day2.toml`. Title SHALL be `6.3. Alert Management`.

description SHALL be:

Parent section covering alert management including active alerts, receiver
configuration, and update retrieval. Effective alerting ensures operational
issues are detected and routed to the appropriate teams.

recommendation SHALL be:

This parent is Alertmanager routing, not the firing-alert table. Grep receiver and route names only — the secret can contain webhook URLs.

verification SHALL be:

1. Print Alertmanager receiver and route names from the secret. The secret can contain webhook URLs — do not dump the full content.
   `oc -n openshift-monitoring get secret alertmanager-main -o jsonpath='{.data.alertmanager.yaml}' | base64 -d | grep -E '^(receivers:|route:)|severity:'`
2. Verify receivers are configured for critical and warning routes.
3. Verify alert inhibition rules prevent noise.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.20` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.20/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`.

#### Scenario: 7.6.tsr.6_3_alert_management loads
- WHEN `get_entry` is called with `7.6.tsr.6_3_alert_management`
- THEN the title is `6.3. Alert Management`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_3_2_alert_receivers
`load_kb()` SHALL contain `7.6.tsr.6_3_2_alert_receivers` from `7_6_day2.toml`. Title SHALL be `6.3.2. Alert Receivers`.

description SHALL be:

Validates that Alertmanager has configured receivers (email, PagerDuty, Slack,
webhook) to route alerts to operations teams. Without receivers, firing alerts
go unnoticed and incidents are detected only by user impact.

recommendation SHALL be:

Configure Alertmanager receivers so critical pages and warning notifies. Without receivers, alerts fire into the void. Print names from the secret; do not dump webhook URLs or credentials.

verification SHALL be:

1. Print Alertmanager receiver and route names. The secret can contain webhook URLs — print names only.
   `oc -n openshift-monitoring get secret alertmanager-main -o jsonpath='{.data.alertmanager.yaml}' | base64 -d | grep -E '^(receivers:|route:)|name:|severity:'`
2. Ensure critical alerts route to a paging system.
3. Ensure warnings route to a notification channel.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

alertmanager routing configuration

impact_detail SHALL be:

Alertmanager config changes reload the alertmanager pods without restarting nodes or disrupting monitored workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/managing_alerts/index#configuring-alert-receivers_configuring-the-monitoring-stack`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/managing_alerts/index#configuring-alert-receivers_configuring-the-monitoring-stack`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/managing_alerts/index#configuring-alert-receivers_configuring-the-monitoring-stack`, `4.20` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.20/html-single/managing_alerts/index#configuring-alert-receivers_configuring-the-monitoring-stack`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/managing_alerts/index#configuring-alert-receivers_configuring-the-monitoring-stack`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/managing_alerts/index#configuring-alert-receivers_configuring-the-monitoring-stack`.

#### Scenario: 7.6.tsr.6_3_2_alert_receivers loads
- WHEN `get_entry` is called with `7.6.tsr.6_3_2_alert_receivers`
- THEN the title is `6.3.2. Alert Receivers`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_3_3_retrieves_updates
`load_kb()` SHALL contain `7.6.tsr.6_3_3_retrieves_updates` from `7_6_day2.toml`. Title SHALL be `6.3.3. Retrieves Updates`.

description SHALL be:

Checks whether the cluster can retrieve available update information from the
upstream update service. Inability to retrieve updates indicates network,
proxy, or Telemetry connectivity issues.

recommendation SHALL be:

Restore CVO `RetrievedUpdates=False` by fixing proxy, firewall, or disconnected mirroring. Egress must reach `api.openshift.com` and the Red Hat CDN unless this cluster is offline by design.

verification SHALL be:

1. Print the RetrievedUpdates condition from ClusterVersion. **PASS** if `Status=True`; investigate if False.
   `oc get clusterversion version -o jsonpath='{range .status.conditions[?(@.type=="RetrievedUpdates")]}{.type}={.status} reason={.reason}{"\n"}{end}'`
2. If RetrievedUpdates is False, print proxy endpoints to check for egress issues.
   `oc get proxy cluster -o jsonpath='{.spec.httpProxy}{"\t"}{.spec.httpsProxy}{"\t"}{.spec.noProxy}{"\n"}'`
3. Ensure egress allows access to `api.openshift.com` and Red Hat CDN endpoints.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

cluster-wide nodes and system egress

impact_detail SHALL be:

Changing the Proxy object causes the Machine Config Operator to roll and reboot nodes so system components inherit the new proxy settings.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#understanding-openshift-updates`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#understanding-openshift-updates`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#understanding-openshift-updates`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#understanding-openshift-updates`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#understanding-openshift-updates`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#understanding-openshift-updates`.

#### Scenario: 7.6.tsr.6_3_3_retrieves_updates loads
- WHEN `get_entry` is called with `7.6.tsr.6_3_3_retrieves_updates`
- THEN the title is `6.3.3. Retrieves Updates`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_4_certificate_management
`load_kb()` SHALL contain `7.6.tsr.6_4_certificate_management` from `7_6_day2.toml`. Title SHALL be `6.4. Certificate Management`.

`content_from` SHALL be `7.6.csr_pending` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.tsr.6_4_certificate_management loads
- WHEN `get_entry` is called with `7.6.tsr.6_4_certificate_management`
- THEN the title is `6.4. Certificate Management`
- AND `content_from` is `7.6.csr_pending`


### Requirement: KB 7.6.tsr.6_4_1_pending_certificate_requests
`load_kb()` SHALL contain `7.6.tsr.6_4_1_pending_certificate_requests` from `7_6_day2.toml`. Title SHALL be `6.4.1. Pending Certificate Requests`.

`content_from` SHALL be `7.6.csr_pending` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.tsr.6_4_1_pending_certificate_requests loads
- WHEN `get_entry` is called with `7.6.tsr.6_4_1_pending_certificate_requests`
- THEN the title is `6.4.1. Pending Certificate Requests`
- AND `content_from` is `7.6.csr_pending`


### Requirement: KB 7.6.tsr.6_4_2_custom_certificates
`load_kb()` SHALL contain `7.6.tsr.6_4_2_custom_certificates` from `7_6_day2.toml`. Title SHALL be `6.4.2. Custom Certificates`.

description SHALL be:

Evaluates user-provided certificates for API server, ingress, and custom routes
for expiration risk. Unlike internal OCP certificates that auto-rotate, custom
certificates require manual renewal before expiry.

recommendation SHALL be:

Renew user-provided API, ingress, and route certificates at least 30 days before `enddate`. Platform-managed serving certs rotate on their own and are not this finding.

verification SHALL be:

1. Print the ingress certificate expiration date. **FAIL** if it expires within 30 days.
   `oc get secret -n openshift-ingress router-certs-default -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -enddate`
2. Review API server serving certs and any custom route certificates.
3. Plan renewal at least 30 days before expiration.

impact SHALL be:

workload-shift

impact_scope SHALL be:

affected ingress or API endpoints

impact_detail SHALL be:

Renewing certificates rolls the components that mount those TLS resources and can briefly reset TLS sessions.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#security-platform-certificates_security-platform`.

#### Scenario: 7.6.tsr.6_4_2_custom_certificates loads
- WHEN `get_entry` is called with `7.6.tsr.6_4_2_custom_certificates`
- THEN the title is `6.4.2. Custom Certificates`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_5_node_ssh_accessed
`load_kb()` SHALL contain `7.6.tsr.6_5_node_ssh_accessed` from `7_6_day2.toml`. Title SHALL be `6.5. Node SSH Accessed`.

description SHALL be:

This check is sshd Accepted publickey or session opened in node journals. Any row is **WARNING**. Empty is **PASS** none-ssh.

recommendation SHALL be:

Treat `Accepted publickey` or `session opened` in node journals as evidence that someone used node SSH. Correlate with change windows. Empty journals mean no SSH login in the window. Do not treat MachineConfig drift as the same finding.

verification SHALL be:

1. Search node journals for SSH login evidence (Accepted publickey or session opened). **WARNING** for each row found; **PASS** if the list is empty. If the node-logs API is unavailable, the command prints **INFO** — skip.
   `oc adm node-logs $(oc get nodes -o jsonpath='{.items[*].metadata.name}') -u sshd -g 'Accepted publickey|session opened' --since=-30d 2>&1 | awk '/at least one node name|Forbidden/{print "INFO n/a-node-logs"; n=1; next} n{next} NF{print "WARNING", $0; c++} END{if(!n && !c) print "PASS none-ssh"}'`

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#ssh-access-to-cluster-nodes_investigating-pod-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#ssh-access-to-cluster-nodes_investigating-pod-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#ssh-access-to-cluster-nodes_investigating-pod-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#ssh-access-to-cluster-nodes_investigating-pod-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#ssh-access-to-cluster-nodes_investigating-pod-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#ssh-access-to-cluster-nodes_investigating-pod-issues`.

#### Scenario: 7.6.tsr.6_5_node_ssh_accessed loads
- WHEN `get_entry` is called with `7.6.tsr.6_5_node_ssh_accessed`
- THEN the title is `6.5. Node SSH Accessed`
- AND `content_from` is empty


### Requirement: KB 7.6.tsr.6_6_upgrade_management
`load_kb()` SHALL contain `7.6.tsr.6_6_upgrade_management` from `7_6_day2.toml`. Title SHALL be `6.6. Upgrade Management`.

`content_from` SHALL be `7.6.tsr.6_6_1_machine_config_pool_max_unavailable` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.6.tsr.6_6_upgrade_management loads
- WHEN `get_entry` is called with `7.6.tsr.6_6_upgrade_management`
- THEN the title is `6.6. Upgrade Management`
- AND `content_from` is `7.6.tsr.6_6_1_machine_config_pool_max_unavailable`


### Requirement: KB 7.6.tsr.6_6_1_machine_config_pool_max_unavailable
`load_kb()` SHALL contain `7.6.tsr.6_6_1_machine_config_pool_max_unavailable` from `7_6_day2.toml`. Title SHALL be `6.6.1. Machine Config Pool Max Unavailable`.

description SHALL be:

Evaluates the `maxUnavailable` setting on `MachineConfigPool`s which controls how
many nodes can be drained simultaneously during upgrades. Too high a value
risks capacity loss; too low extends maintenance windows unnecessarily.

recommendation SHALL be:

Keep control-plane MCP `maxUnavailable` at 1. For worker MCPs, set `maxUnavailable` to the largest absolute number or percentage of nodes that can be unavailable while preserving application capacity, replica availability, disruption budgets, and VM migration headroom. The number or percentage is dependent on the capacity of the cluster. If the cluster is N+1 then a single unavailable is the best that can be done.

verification SHALL be:

1. Print `maxUnavailable`, machine count, and ready count per `MachineConfigPool`.
   `oc get mcp -o custom-columns=NAME:.metadata.name,MAXUNAVAILABLE:.spec.maxUnavailable,MACHINECOUNT:.status.machineCount,READY:.status.readyMachineCount`
2. For production clusters, set `maxUnavailable` to 1 or a small percentage to minimize capacity loss during rolling updates.
3. For non-production clusters, higher values accelerate rollout.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

MachineConfigPool rollout behavior

impact_detail SHALL be:

Changing `maxUnavailable` affects how future upgrades are paced but does not itself trigger node reboots.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#update-using-custom-machine-config-pools-canary_updating-cluster-within-minor`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#update-using-custom-machine-config-pools-canary_updating-cluster-within-minor`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#update-using-custom-machine-config-pools-canary_updating-cluster-within-minor`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#update-using-custom-machine-config-pools-canary_updating-cluster-within-minor`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#update-using-custom-machine-config-pools-canary_updating-cluster-within-minor`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#update-using-custom-machine-config-pools-canary_updating-cluster-within-minor`.

#### Scenario: 7.6.tsr.6_6_1_machine_config_pool_max_unavailable loads
- WHEN `get_entry` is called with `7.6.tsr.6_6_1_machine_config_pool_max_unavailable`
- THEN the title is `6.6.1. Machine Config Pool Max Unavailable`
- AND `content_from` is empty


### Requirement: KB 7.7.scc.custom
`load_kb()` SHALL contain `7.7.scc.custom` from `7_7_security.toml`. Title SHALL be `Custom SCCs`.

description SHALL be:

This check identifies custom SecurityContextConstraints (SCCs) that do not appear to be managed by the OpenShift payload or an installed Operator. SCCs owned by ClusterVersion, marked with include.release.openshift.io, or labeled as managed by an application are excluded; any remaining SCC is reported as a **WARNING** because it represents a cluster-specific security policy requiring customer ownership and review. An empty result is **PASS**, indicating that no unmanaged custom SCCs were identified. SCCs control security-sensitive pod permissions, including privilege escalation, host access, volume types, capabilities, and user or SELinux settings.

recommendation SHALL be:

Review each custom SCC to confirm purpose and continued need. Apply least privilege: grant access through RBAC to specific service accounts rather than broad users or groups, avoid unnecessary priority settings, and restrict privileged containers, host namespaces, host-path volumes, capabilities, and arbitrary UID use wherever possible. Document each approved custom SCC. Do not modify OpenShift-provided SCCs. Create or maintain a separate custom SCC when a supported workload requires an exception.

verification SHALL be:

1. List custom SCCs with no ClusterVersion owner, no include.release.openshift.io annotation, and no app.kubernetes.io/managed-by label. Any printed row needs review; an empty result is healthy.
   `oc get scc -o json | jq -r '.items[] | (.metadata.annotations // {}) as $annotations | (.metadata.labels // {}) as $labels | (.metadata.ownerReferences // []) as $owners | select(([$owners[].kind] | index("ClusterVersion") | not) and (([$annotations | keys[] | select(startswith("include.release.openshift.io/"))] | length) == 0) and (($labels["app.kubernetes.io/managed-by"] // "") == "")) | .metadata.name' | awk 'NF{print "WARNING", "NAME="$0; c++} END{if(!c) print "PASS none-custom"}'`
2. For each reported SCC, print its privilege and run-as-user settings.
   `oc get scc <name>`
3. Print the users and groups bound to the SCC.
   `oc get scc <name> -o json | jq -r '[((.users // []) | join(",")), ((.groups // []) | join(","))] | @tsv' | awk -F'\t' '{users=($1==""?"none":$1); groups=($2==""?"none":$2); print "INFO", "USERS="users, "GROUPS="groups}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads currently using custom SCCs

impact_detail SHALL be:

Removing elevated SCC access usually requires workload rollout or restart under a less-privileged security context.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`.

#### Scenario: 7.7.scc.custom loads
- WHEN `get_entry` is called with `7.7.scc.custom`
- THEN the title is `Custom SCCs`
- AND `content_from` is empty


### Requirement: KB 7.7.scc.privileged_users
`load_kb()` SHALL contain `7.7.scc.privileged_users` from `7_7_security.toml`. Title SHALL be `Privileged SCC usage`.

description SHALL be:

The `privileged` SCC grants unrestricted host access. Only system service
accounts should normally require it. Audit all non-system principals with this
assignment and revoke access where it is not strictly required.

recommendation SHALL be:

Only documented system service accounts should hold the `privileged` SCC. List USERS and GROUPS on the object, then migrate non-system workloads to a tighter SCC before revoking — pods fail to start if access is removed first. Do not delete the privileged SCC itself.

verification SHALL be:

1. List the principals (users and groups) on the `privileged` SCC. Non-system subjects need review.
   `oc get scc privileged -o jsonpath='{.users}{"\n"}{.groups}{"\n"}'`
2. Verify each listed principal has a documented requirement for privileged access.
3. For subjects that can be moved, migrate to a less-privileged SCC and confirm pod startup before revoking.

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads using the privileged SCC

impact_detail SHALL be:

Revoking privileged SCC access often requires pod rollout or manifest changes so workloads can start under a less-privileged policy.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/authentication_and_authorization/index#role-based-access-to-scc_configuring-internal-oauth`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/authentication_and_authorization/index#role-based-access-to-scc_configuring-internal-oauth`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/authentication_and_authorization/index#role-based-access-to-scc_configuring-internal-oauth`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index#role-based-access-to-scc_configuring-internal-oauth`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/authentication_and_authorization/index#role-based-access-to-scc_configuring-internal-oauth`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/authentication_and_authorization/index#role-based-access-to-scc_configuring-internal-oauth`.

#### Scenario: 7.7.scc.privileged_users loads
- WHEN `get_entry` is called with `7.7.scc.privileged_users`
- THEN the title is `Privileged SCC usage`
- AND `content_from` is empty


### Requirement: KB 7.7.oauth.idp
`load_kb()` SHALL contain `7.7.oauth.idp` from `7_7_security.toml`. Title SHALL be `External identity providers`.

description SHALL be:

This check fires when no OAuth identity providers are configured, leaving only
the bootstrap `kubeadmin` account. After at least one working IdP exists and a
non-kubeadmin cluster-admin can log in, remove the kubeadmin secret.

recommendation SHALL be:

No identity provider means the cluster still lives on kubeadmin. HTPasswd counts as an IdP. Configure a working IdP and a non-kubeadmin cluster-admin before you delete the kubeadmin secret.

verification SHALL be:

1. Print the name and type of each identity provider (OAuth cluster). Any listed row confirms an IdP is configured; an empty result means no IdP exists and needs attention.
   `oc get oauth cluster -o jsonpath='{range .spec.identityProviders[*]}{.name}{"\t"}{.type}{"\n"}{end}' | awk -F'\t' 'NF{print "PASS", "NAME="$1, "TYPE="$2; c++} END{if(!c) print "WARNING none-idp"}'`
2. If no IdP exists, configure one (LDAP, OIDC, GitHub, GitLab, HTPasswd, or another supported type).
3. Confirm a non-kubeadmin user holds `cluster-admin` and can authenticate.
4. Only then delete the bootstrap kubeadmin secret.
   `oc delete secret kubeadmin -n kube-system`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

authentication components

impact_detail SHALL be:

Editing the OAuth configuration rolls authentication pods and can briefly affect user logins, but it does not reboot nodes or stop running workloads.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/authentication_and_authorization/index#configuring-identity-providers`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/authentication_and_authorization/index#configuring-identity-providers`.

#### Scenario: 7.7.oauth.idp loads
- WHEN `get_entry` is called with `7.7.oauth.idp`
- THEN the title is `External identity providers`
- AND `content_from` is empty


### Requirement: KB 7.7.rbac.cluster_admin
`load_kb()` SHALL contain `7.7.rbac.cluster_admin` from `7_7_security.toml`. Title SHALL be `Cluster-admin RBAC`.

description SHALL be:

This check identifies cluster-admin assignments that are not clearly required for core platform operation. It reports non-system: users and groups, leftover must-gather service accounts, and service accounts outside OpenShift or Kubernetes system namespaces; platform-managed operator service accounts in openshift-* and kube-* namespaces are excluded. Any remaining assignment is a **WARNING** because cluster-admin grants unrestricted access across the cluster. An empty result is **PASS**, reported as no non-system user admin, no must-gather admin, or no tenant service-account admin grants.

recommendation SHALL be:

Review every reported cluster-admin binding and confirm whether it is still needed. Remove obsolete must-gather, default-service-account, user, group, and tenant service-account grants and replace them with the smallest namespace-scoped or cluster-scoped role required for the task. Do not assume that every service account is unsafe.

verification SHALL be:

1. Print User and Group subjects on cluster-admin ClusterRoleBindings, excluding system: principals. Any listed row needs review; an empty result is healthy.
   `oc get clusterrolebinding -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name as $binding_name | .subjects[]? | select((.kind=="User" or .kind=="Group") and (.name | startswith("system:") | not)) | [$binding_name, .kind, .name] | @tsv' | awk -F'\t' '{print "WARNING", "BINDING="$1, "KIND="$2, "SUBJECT="$3; c++} END{if(!c) print "PASS none-user-admin"}'`
2. Print leftover must-gather service accounts with cluster-admin. Any listed row needs review; an empty result is healthy.
   `oc get clusterrolebinding -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name as $binding_name | .subjects[]? | select((.namespace // "") | test("must-gather")) | [$binding_name, .kind, .name, .namespace] | @tsv' | awk -F'\t' '{print "WARNING", "BINDING="$1, "KIND="$2, "SUBJECT="$3, "NS="$4; c++} END{if(!c) print "PASS none-must-gather-admin"}'`
3. Print service accounts outside openshift-* and kube-* namespaces that hold cluster-admin. Any listed row needs review; an empty result is healthy.
   `oc get clusterrolebinding -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name as $binding_name | .subjects[]? | select(.kind=="ServiceAccount" and ((.namespace // "") | test("^(openshift-|kube-)") | not)) | [$binding_name, .kind, .name, (.namespace // "-")] | @tsv' | awk -F'\t' '{print "WARNING", "BINDING="$1, "KIND="$2, "SUBJECT="$3, "NS="$4; c++} END{if(!c) print "PASS none-tenant-sa-admin"}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

access control only

impact_detail SHALL be:

RBAC binding changes apply immediately without restarting nodes, but they can instantly remove administrative access for the affected principals.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/authentication_and_authorization/index#viewing-cluster-roles_using-rbac`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/authentication_and_authorization/index#viewing-cluster-roles_using-rbac`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/authentication_and_authorization/index#viewing-cluster-roles_using-rbac`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index#viewing-cluster-roles_using-rbac`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/authentication_and_authorization/index#viewing-cluster-roles_using-rbac`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/authentication_and_authorization/index#viewing-cluster-roles_using-rbac`.

#### Scenario: 7.7.rbac.cluster_admin loads
- WHEN `get_entry` is called with `7.7.rbac.cluster_admin`
- THEN the title is `Cluster-admin RBAC`
- AND `content_from` is empty


### Requirement: KB 7.7.compliance
`load_kb()` SHALL contain `7.7.compliance` from `7_7_security.toml`. Title SHALL be `Compliance Operator`.

description SHALL be:

The Compliance Operator automates security scanning against profiles such as
CIS, NIST, and STIG, and provides continuous monitoring plus supported
remediation workflows.

recommendation SHALL be:

The Compliance Operator is how you scan CIS/NIST/STIG on a cadence. Missing CSV or a suite that never reaches DONE means you have no continuous baseline. Review remediations before apply — some roll nodes.

verification SHALL be:

1. Check whether the Compliance Operator CSV is installed.
   `oc get csv -n openshift-compliance`
2. Print the ComplianceSuite name, phase, and schedule. A suite not reaching DONE means scanning is not completing.
   `oc get compliancesuite -n openshift-compliance -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,SCHEDULE:.spec.schedule`
3. If the operator is missing, install it in `openshift-compliance` and select a benchmark profile such as CIS or NIST.
4. Review generated remediations before applying; some roll nodes or change control-plane configuration.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

compliance operator and scan workloads

impact_detail SHALL be:

Deploying the Compliance Operator and running scans adds cluster load and creates scan pods, but it does not reboot nodes by itself.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#compliance-operator-scan-management`.

#### Scenario: 7.7.compliance loads
- WHEN `get_entry` is called with `7.7.compliance`
- THEN the title is `Compliance Operator`
- AND `content_from` is empty


### Requirement: KB 7.7.csr
`load_kb()` SHALL contain `7.7.csr` from `7_7_security.toml`. Title SHALL be `Certificate signing requests`.

`content_from` SHALL be `7.6.csr_pending` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.csr loads
- WHEN `get_entry` is called with `7.7.csr`
- THEN the title is `Certificate signing requests`
- AND `content_from` is `7.6.csr_pending`


### Requirement: KB 7.7.ccx_external.cve_2026_31431_copy_fail_in_algif_aead
`load_kb()` SHALL contain `7.7.ccx_external.cve_2026_31431_copy_fail_in_algif_aead` from `7_7_security.toml`. Title SHALL be `CCX CVE-2026-31431 kernel algif_aead`.

description SHALL be:

This check determines whether the cluster is running an OpenShift version that includes the kernel fix for CVE-2026-31431 (Copy Fail), a Linux kernel vulnerability in the algif_aead cryptographic interface. The first fixed z-streams are OpenShift 4.16.61, 4.18.40, 4.19.30, 4.20.21, and 4.21.14. A cluster running below the applicable fixed z-stream is reported as **FAIL**; a cluster at or above the fixed release is **PASS**. The remediation is delivered through the updated node kernel included in the applicable OpenShift z-stream.

recommendation SHALL be:

Upgrade the cluster to a fixed OpenShift z-stream for CVE-2026-31431 (Copy Fail): at minimum 4.18.40 for the current 4.18 release, or a supported later target such as 4.19.30, 4.20.21, or 4.21.14. Versions below the applicable fixed release retain the vulnerable kernel; the upgrade delivers the corrected kernel and requires managed node reboots as part of rollout. Use oc adm upgrade to review eligible targets and select an approved update path, then perform the upgrade during a planned maintenance window.

verification SHALL be:

1. Compare the ClusterVersion against the first fixed z-stream. Below the fix level needs action; at or above is healthy. If the minor version is unrecognized, the result is informational.
   `oc get clusterversion version --no-headers -o custom-columns=VERSION:.status.desired.version | awk -F. '{minor=$2+0; zstream=$3+0; result="FAIL"; fixed="unknown"; if(minor==21){fixed="4.21.14"; if(zstream>=14) result="PASS"} else if(minor==20){fixed="4.20.21"; if(zstream>=21) result="PASS"} else if(minor==19){fixed="4.19.30"; if(zstream>=30) result="PASS"} else if(minor==18){fixed="4.18.40"; if(zstream>=40) result="PASS"} else if(minor==16){fixed="4.16.61"; if(zstream>=61) result="PASS"} else if(minor>=22){result="PASS"; fixed=">=4.22"} else {result="INFO"; fixed="n/a-stream"}; print result, "VERSION="$0, "FIXED="fixed}'`
2. On a failing result, review available updates (does not start an upgrade).
   `oc adm upgrade`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster nodes running the affected kernel

impact_detail SHALL be:

Applying the fixed RHCOS/kernel content requires rolling node updates and reboots to bring the patched kernel into service.

priority_hint SHALL be:

P1

Links SHALL be `default` -> `https://access.redhat.com/security/cve/CVE-2026-31431`, `4.18` -> `https://access.redhat.com/security/cve/CVE-2026-31431`, `4.19` -> `https://access.redhat.com/security/cve/CVE-2026-31431`, `4.20` -> `https://access.redhat.com/security/cve/CVE-2026-31431`, `4.21` -> `https://access.redhat.com/security/cve/CVE-2026-31431`, `4.22` -> `https://access.redhat.com/security/cve/CVE-2026-31431`.

#### Scenario: 7.7.ccx_external.cve_2026_31431_copy_fail_in_algif_aead loads
- WHEN `get_entry` is called with `7.7.ccx_external.cve_2026_31431_copy_fail_in_algif_aead`
- THEN the title is `CCX CVE-2026-31431 kernel algif_aead`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_external.cve_2026_43284_dirty_frag
`load_kb()` SHALL contain `7.7.ccx_external.cve_2026_43284_dirty_frag` from `7_7_security.toml`. Title SHALL be `CCX CVE-2026-43284 dirty frag`.

description SHALL be:

This check verifies whether the cluster is running an OpenShift Container Platform release that includes the kernel remediation for CVE-2026-43284 (Dirty Frag), an Important Linux kernel local privilege-escalation vulnerability affecting the XFRM/ESP and RxRPC subsystems. The first fixed z-streams are 4.12.90, 4.14.66, 4.16.62, 4.18.41, 4.19.31, 4.20.22, and 4.21.15. The remediation is provided by the updated kernel included in the applicable OpenShift z-stream.

recommendation SHALL be:

Upgrade the cluster to the first fixed z-stream for its supported OpenShift minor release (4.18.41 or later) or move to an eligible later supported target such as 4.19.31, 4.20.22, or 4.21.15. Do not consider the cluster remediated until it is running a release that includes the corrected kernel; a version below the listed fixed release remains vulnerable.

verification SHALL be:

1. Compare the ClusterVersion against the first fixed z-stream. Below the fix level needs action; at or above is healthy. If the minor version is unrecognized, the result is informational.
   `oc get clusterversion version --no-headers -o custom-columns=VERSION:.status.desired.version | awk -F. '{minor=$2+0; zstream=$3+0; result="FAIL"; fixed="unknown"; if(minor==21){fixed="4.21.15"; if(zstream>=15) result="PASS"} else if(minor==20){fixed="4.20.22"; if(zstream>=22) result="PASS"} else if(minor==19){fixed="4.19.31"; if(zstream>=31) result="PASS"} else if(minor==18){fixed="4.18.41"; if(zstream>=41) result="PASS"} else if(minor==16){fixed="4.16.62"; if(zstream>=62) result="PASS"} else if(minor==14){fixed="4.14.66"; if(zstream>=66) result="PASS"} else if(minor==12){fixed="4.12.90"; if(zstream>=90) result="PASS"} else if(minor>=22){result="PASS"; fixed=">=4.22"} else {result="INFO"; fixed="n/a-stream"}; print result, "VERSION="$0, "FIXED="fixed}'`
2. On a failing result, review available updates (does not start an upgrade).
   `oc adm upgrade`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster nodes running the affected kernel

impact_detail SHALL be:

Applying the fixed RHCOS/kernel content requires rolling node updates and reboots to bring the patched kernel into service.

priority_hint SHALL be:

P1

Links SHALL be `default` -> `https://access.redhat.com/security/cve/CVE-2026-43284`, `4.18` -> `https://access.redhat.com/security/cve/CVE-2026-43284`, `4.19` -> `https://access.redhat.com/security/cve/CVE-2026-43284`, `4.20` -> `https://access.redhat.com/security/cve/CVE-2026-43284`, `4.21` -> `https://access.redhat.com/security/cve/CVE-2026-43284`, `4.22` -> `https://access.redhat.com/security/cve/CVE-2026-43284`.

#### Scenario: 7.7.ccx_external.cve_2026_43284_dirty_frag loads
- WHEN `get_entry` is called with `7.7.ccx_external.cve_2026_43284_dirty_frag`
- THEN the title is `CCX CVE-2026-43284 dirty frag`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.high_severity_alerts
`load_kb()` SHALL contain `7.7.ccx_internal.high_severity_alerts` from `7_7_security.toml`. Title SHALL be `CCX high severity alerts`.

description SHALL be:

Indicates firing Prometheus alerts with severity critical or warning. Any critical alert is considered a **FAIL** while any warning alert is **WARNING**.

recommendation SHALL be:

Investigate and resolve all firing Prometheus alerts according to their severity. Treat critical alerts as active incidents requiring immediate triage and remediation. Warnings still need to be remediated even when it does not require immediate intervention. An empty result confirms that no high-severity alerts are currently firing.

verification SHALL be:

1. Print firing Prometheus alerts with severity critical or warning. A critical alert needs immediate action; a warning needs review. An empty result means no high-severity alerts are firing.
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | select(.state=="firing" and (.labels.severity=="critical" or .labels.severity=="warning")) | [.state, .labels.alertname, .labels.severity] | @tsv' | awk -F'\t' '{r="FAIL"; if($3=="warning") r="WARNING"; print r, "STATE="$1, "ALERT="$2, "SEVERITY="$3} END{if(NR==0) print "PASS none-high-severity"}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

whatever the alertname names, often control plane

impact_detail SHALL be:

Clearing a firing critical alert follows that alert's runbook. Do not silence it. The remediating change is usually planned control-plane or node work.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.18` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.18/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.19` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.19/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.20` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.20/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.21` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.21/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`, `4.22` -> `https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/4.22/html-single/managing_alerts/index#getting-information-about-alerts-silences-and-alerting-rules_managing-alerts-as-an-administrator`.

#### Scenario: 7.7.ccx_internal.high_severity_alerts loads
- WHEN `get_entry` is called with `7.7.ccx_internal.high_severity_alerts`
- THEN the title is `CCX high severity alerts`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.high_core_dns_errors_high_alerts
`load_kb()` SHALL contain `7.7.ccx_internal.high_core_dns_errors_high_alerts` from `7_7_security.toml`. Title SHALL be `CCX high CoreDNS error rate`.

`content_from` SHALL be `7.1.tsr.1_5_2_3_dns_alerts` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.high_core_dns_errors_high_alerts loads
- WHEN `get_entry` is called with `7.7.ccx_internal.high_core_dns_errors_high_alerts`
- THEN the title is `CCX high CoreDNS error rate`
- AND `content_from` is `7.1.tsr.1_5_2_3_dns_alerts`


### Requirement: KB 7.7.ccx_internal.certificates_expiring_soon
`load_kb()` SHALL contain `7.7.ccx_internal.certificates_expiring_soon` from `7_7_security.toml`. Title SHALL be `CCX certificates expiring soon`.

description SHALL be:

This check evaluates the expiration dates of TLS certificates used by the OpenShift ingress controller, openshift-config resources, named API server certificates, and cert-manager-managed certificates when cert-manager is installed. Certificates expiring within 30 days are reported as **FAIL**, certificates expiring within 90 days as **WARNING**, and certificates with more than 90 days remaining as **PASS**. The absence of a custom default ingress certificate, named API certificate, or cert-manager CRDs is recorded as **INFO** / N/A for that specific certificate source, not as a failure. This check does not evaluate pending Certificate Signing Requests (CSRs), which are reported separately under the CSR-pending check.

recommendation SHALL be:

Renew or replace any user-managed TLS certificate that expires within 30 days as an immediate priority, and schedule renewal of certificates expiring within 90 days before they enter the critical window. OpenShift-managed serving certificates normally rotate automatically, while custom ingress, named API server, and externally managed certificates require the responsible team to maintain the renewal process.

verification SHALL be:

1. Check whether the default IngressController uses a custom certificate. If the value is empty, no custom ingress cert is configured and the platform default is in use.
   `oc get ingresscontroller default -n openshift-ingress-operator --no-headers -o custom-columns=DEFAULTCERT:.spec.defaultCertificate.name | awk '{if($1=="<none>" || $1=="") print "INFO n/a-custom-ingress-cert"; else print "INFO", "DEFAULTCERT="$1}'`
2. Print API server named-certificate secret names. If the list is empty, no named API certificates are configured.
   `oc get apiserver cluster -o jsonpath='{range .spec.servingCerts.namedCertificates[*]}{.servingCertificate.name}{"\n"}{end}' | awk 'NF{print "INFO", "NAME="$1} END{if(NR==0) print "INFO n/a-named-api-cert"}'`
3. Check kubernetes.io/tls secrets in openshift-ingress and openshift-config. Certificates expiring within 30 days need immediate action; within 90 days need review. If no TLS secrets are found, the result is informational.
   `for namespace in openshift-ingress openshift-config; do oc get secret -n "$namespace" --field-selector type=kubernetes.io/tls -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.data.tls\.crt}{"\n"}{end}'; done | while IFS=$'\t' read -r namespace secret_name certificate; do [ -n "$certificate" ] || continue; cert_pem=$(printf '%s' "$certificate" | base64 -d 2>/dev/null) || continue; enddate=$(printf '%s' "$cert_pem" | openssl x509 -noout -enddate 2>/dev/null | sed 's/^notAfter=//'); days=$(( ($(date -d "$enddate" +%s) - $(date +%s)) / 86400 )); result=PASS; [ "$days" -lt 90 ] && result=WARNING; [ "$days" -lt 30 ] && result=FAIL; echo "$result NS=$namespace NAME=$secret_name DAYS=$days ENDDATE=$enddate"; done | awk 'NF{print; found=1} END{if(!found) print "INFO n/a-tls"}'`
4. Print cert-manager Certificate readiness and expiry. If the CRD is missing, cert-manager is not installed; if no certificates exist, none are managed. A certificate not showing Ready True needs action.
   `oc get certificate -A --no-headers -o 'custom-columns=NS:.metadata.namespace,NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status,NOTAFTER:.status.notAfter' 2>&1 | awk '/No resources found/{print "INFO n/a-cert-manager-cert"; seen=1; next} /doesn.t have a resource type|could not find the requested resource/{print "INFO n/a-cert-manager"; seen=1; next} seen{next} {r="INFO"; if($3!="True") r="FAIL"; print r, "NS="$1, "NAME="$2, "READY="$3, "NOTAFTER="$4} END{if(!seen && NR==0) print "INFO n/a-cert-manager-cert"}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

affected ingress, API, or authentication endpoints

impact_detail SHALL be:

Renewing user-provided certificates rolls the components that mount those TLS resources and can briefly reset TLS sessions while new certs are loaded.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#security-platform-certificates_security-platform`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#security-platform-certificates_security-platform`.

#### Scenario: 7.7.ccx_internal.certificates_expiring_soon loads
- WHEN `get_entry` is called with `7.7.ccx_internal.certificates_expiring_soon`
- THEN the title is `CCX certificates expiring soon`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.etcd_low_backend_performance
`load_kb()` SHALL contain `7.7.ccx_internal.etcd_low_backend_performance` from `7_7_security.toml`. Title SHALL be `CCX etcd low backend performance`.

description SHALL be:

Red Hat Insights detected that etcd is taking too long to write data to disk on one or more control plane nodes. The evidence shows slow fdatasync and backend commit times. When etcd cannot write fast enough, the cluster's API becomes slow or unresponsive — every kubectl/oc command and every controller reconciliation is affected.

recommendation SHALL be:

Storage is too slow for etcd. Move etcd to dedicated NVMe or enterprise SSD; BareMetal IPI needs high-IOPS disks. Do not retune etcd to hide slow disks. Confirm member health and DB size first; defrag above ~4 GB only after a backup.

verification SHALL be:

1. Check etcd database size and member health.
   `oc -n openshift-etcd exec -c etcd etcd-<member> -- etcdctl endpoint status --cluster -w table`
2. Run fio benchmarks on control-plane disks to verify minimum 50 sequential IOPS and P99 fsync latency under 10 ms.
3. If disk latency is too high, on bare metal dedicate an NVMe/SSD partition for /var/lib/etcd; on virtualized platforms check for noisy-neighbor I/O contention.
4. If the database exceeds 4 GB, schedule defragmentation in a maintenance window after taking an etcd backup.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane and etcd storage path

impact_detail SHALL be:

Remediating etcd backend performance often requires control-plane infrastructure or storage changes that can reduce API capacity during the work.

`finding_group` SHALL be `etcd-disk-latency`.

`finding_group_title` SHALL be `TSR etcd disk performance`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#etcd-verify-hardware_recommended-etcd-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-verify-hardware_etcd-practices`.

#### Scenario: 7.7.ccx_internal.etcd_low_backend_performance loads
- WHEN `get_entry` is called with `7.7.ccx_internal.etcd_low_backend_performance`
- THEN the title is `CCX etcd low backend performance`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.operators_check
`load_kb()` SHALL contain `7.7.ccx_internal.operators_check` from `7_7_security.toml`. Title SHALL be `CCX operators check`.

`content_from` SHALL be `7.5.tsr.5_3_operator_state` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.operators_check loads
- WHEN `get_entry` is called with `7.7.ccx_internal.operators_check`
- THEN the title is `CCX operators check`
- AND `content_from` is `7.5.tsr.5_3_operator_state`


### Requirement: KB 7.7.ccx_internal.pods_check_containers
`load_kb()` SHALL contain `7.7.ccx_internal.pods_check_containers` from `7_7_security.toml`. Title SHALL be `CCX pods container health`.

description SHALL be:

One or more pods have containers that are repeatedly crashing (`CrashLoopBackOff`), cannot pull their image (ImagePullBackOff), or are restarting frequently. The evidence lists the specific pods and their restart counts. These failures may indicate application bugs, missing configuration, or infrastructure problems.

recommendation SHALL be:

Treat `CrashLoopBackOff`, ImagePullBackOff, and container Error states as active pod failures and diagnose the cause before deleting or restarting the affected pod. Review the pod events and container logs to identify application failures, invalid configuration, missing secrets or ConfigMaps, image-reference or registry-authentication issues, dependency failures, or resource constraints. Investigate high restart counts separately when the pod is not in `CrashLoopBackOff`, because that represents a restart-frequency issue rather than this specific failure-state finding.

verification SHALL be:

1. List pods in `CrashLoopBackOff`, Error, or ImagePullBackOff state.
   `oc get pods -A | grep -E 'CrashLoop|Error|ImagePull'`
2. For `CrashLoopBackOff` pods, check the previous container log and pod events for the crash reason.
   `oc logs <pod> -n <ns> --previous`
   `oc describe pod <pod> -n <ns>`
3. For ImagePullBackOff pods, verify the image reference is correct, pull secrets are configured, and network connectivity to the registry is working.

impact SHALL be:

workload-shift

impact_scope SHALL be:

CrashLoopBackOff, ImagePullBackOff, and Error containers

impact_detail SHALL be:

Correcting image, configuration, or memory limits restarts those pods. OOMKilled can also mean node memory pressure that needs capacity work.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#investigating-pod-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#investigating-pod-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#investigating-pod-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#investigating-pod-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#investigating-pod-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#investigating-pod-issues`.

#### Scenario: 7.7.ccx_internal.pods_check_containers loads
- WHEN `get_entry` is called with `7.7.ccx_internal.pods_check_containers`
- THEN the title is `CCX pods container health`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.uninstalled_operators_with_leftover_resources
`load_kb()` SHALL contain `7.7.ccx_internal.uninstalled_operators_with_leftover_resources` from `7_7_security.toml`. Title SHALL be `CCX uninstalled operators with leftover resources`.

`content_from` SHALL be `7.3.tsr.3_3_custom_resource_definitions` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.uninstalled_operators_with_leftover_resources loads
- WHEN `get_entry` is called with `7.7.ccx_internal.uninstalled_operators_with_leftover_resources`
- THEN the title is `CCX uninstalled operators with leftover resources`
- AND `content_from` is `7.3.tsr.3_3_custom_resource_definitions`


### Requirement: KB 7.7.ccx_internal.webhooks_check
`load_kb()` SHALL contain `7.7.ccx_internal.webhooks_check` from `7_7_security.toml`. Title SHALL be `CCX webhooks health`.

description SHALL be:

Fail/timeout/tier scoring for both ValidatingWebhookConfiguration and MutatingWebhookConfiguration. Fail count is **WARNING**, timeout>10 is **WARNING**, Fail scoped to openshift-*/kube-system is **FAIL**.

recommendation SHALL be:

Review validating and mutating webhooks for Fail policy, timeout over 10 seconds, and Fail scoped to openshift-*/kube-system. A down backend with Fail rejects or stalls admission cluster-wide.

Validating hooks admit or deny without rewriting the object. Mutating hooks rewrite objects before they are persisted. Inspect validating webhooks first, then mutating webhooks.

verification SHALL be:

1. Validating webhook scan. Count `failurePolicy=Fail` hooks ; more than zero needs review (shipped operators commonly use Fail).
   `oc get validatingwebhookconfigurations -o json | jq '[.items[].webhooks[]? | select(.failurePolicy=="Fail")] | length' | awk '{print ($1==0?"PASS":"WARNING"), "fail_policy="$1}'`
2. Print `CONFIG`, `HOOK`, `TIMEOUT`, `POLICY`, `SERVICE` for `timeoutSeconds>10` . Any listed row needs review.
   `oc get validatingwebhookconfigurations -o json | jq -r '"CONFIG\tHOOK\tTIMEOUT\tPOLICY\tSERVICE", (.items[] as $config | $config.webhooks[]? | select((.timeoutSeconds // 10) > 10) | [$config.metadata.name, .name, (.timeoutSeconds // 10 | tostring), (.failurePolicy // "Ignore"), ((.clientConfig.service.namespace // "-")+"/"+(.clientConfig.service.name // "-"))] | @tsv)' | column -t | awk 'NR==1{print; next} {print; n++} END{print (n==0?"PASS":"WARNING"), n+0, "timeout>10"}'`
      An empty result means no timeout issue.
3. Print Fail hooks whose selector values name `openshift-*`, `kube-system`, `kube-public`, or `default` . Any listed row needs action.
   `oc get validatingwebhookconfigurations -o json | jq -r '"CONFIG\tHOOK\tNS_VALUES", (.items[] as $config | $config.webhooks[]? | select(.failurePolicy=="Fail") | [((.namespaceSelector.matchLabels // {})[]), (.namespaceSelector.matchExpressions[]?.values[]?)] as $ns | select(any($ns[]; type=="string" and (startswith("openshift-") or .=="kube-system" or .=="kube-public" or .=="default"))) | [$config.metadata.name, .name, ($ns|join(","))] | @tsv)' | column -t | awk 'NR==1{print; next} {print; n++} END{print (n==0?"PASS":"FAIL"), n+0, "fail_tier"}'`
      An empty result means no Fail-policy issue. If steps 1–3 are clean, the validating scan is complete.
4. For each remaining SERVICE, check EndpointSlice readiness.
   `oc get endpointslice -n <ns> -l kubernetes.io/service-name=<svc> -o json | jq '{ready: ([.items[].endpoints[]? | select(.conditions.ready==true)] | length), notReady: ([.items[].endpoints[]? | select(.conditions.ready!=true)] | length)}'`
   `ready=0` means the backend is down.

Mutating hooks rewrite objects before they are persisted. The same Fail/timeout/tier checks apply; a down backend blocks those mutations and can stall admission.

5. Mutating webhook scan. Count `failurePolicy=Fail` hooks ; more than zero needs review (shipped operators commonly use Fail).
   `oc get mutatingwebhookconfigurations -o json | jq '[.items[].webhooks[]? | select(.failurePolicy=="Fail")] | length' | awk '{print ($1==0?"PASS":"WARNING"), "fail_policy="$1}'`
6. Print `CONFIG`, `HOOK`, `TIMEOUT`, `POLICY`, `SERVICE` for `timeoutSeconds>10` . Any listed row needs review.
   `oc get mutatingwebhookconfigurations -o json | jq -r '"CONFIG\tHOOK\tTIMEOUT\tPOLICY\tSERVICE", (.items[] as $config | $config.webhooks[]? | select((.timeoutSeconds // 10) > 10) | [$config.metadata.name, .name, (.timeoutSeconds // 10 | tostring), (.failurePolicy // "Ignore"), ((.clientConfig.service.namespace // "-")+"/"+(.clientConfig.service.name // "-"))] | @tsv)' | column -t | awk 'NR==1{print; next} {print; n++} END{print (n==0?"PASS":"WARNING"), n+0, "timeout>10"}'`
      An empty result means no timeout issue.
7. Print Fail hooks whose selector values name `openshift-*`, `kube-system`, `kube-public`, or `default` . Any listed row needs action.
   `oc get mutatingwebhookconfigurations -o json | jq -r '"CONFIG\tHOOK\tNS_VALUES", (.items[] as $config | $config.webhooks[]? | select(.failurePolicy=="Fail") | [((.namespaceSelector.matchLabels // {})[]), (.namespaceSelector.matchExpressions[]?.values[]?)] as $ns | select(any($ns[]; type=="string" and (startswith("openshift-") or .=="kube-system" or .=="kube-public" or .=="default"))) | [$config.metadata.name, .name, ($ns|join(","))] | @tsv)' | column -t | awk 'NR==1{print; next} {print; n++} END{print (n==0?"PASS":"FAIL"), n+0, "fail_tier"}'`
      An empty result means no Fail-policy issue. If steps 5–7 are clean, the mutating scan is complete.
8. For each remaining SERVICE, check EndpointSlice readiness.
   `oc get endpointslice -n <ns> -l kubernetes.io/service-name=<svc> -o json | jq '{ready: ([.items[].endpoints[]? | select(.conditions.ready==true)] | length), notReady: ([.items[].endpoints[]? | select(.conditions.ready!=true)] | length)}'`
   `ready=0` means the backend is down.

impact SHALL be:

none

`include_in_findings` SHALL be false.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/architecture/index#configuring-dynamic-admission_admission-plug-ins`.

#### Scenario: 7.7.ccx_internal.webhooks_check loads
- WHEN `get_entry` is called with `7.7.ccx_internal.webhooks_check`
- THEN the title is `CCX webhooks health`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.image_registry_storage_comprehensive
`load_kb()` SHALL contain `7.7.ccx_internal.image_registry_storage_comprehensive` from `7_7_security.toml`. Title SHALL be `CCX image registry storage`.

`content_from` SHALL be `7.3.tsr.3_6_2_registry_storage_type` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.image_registry_storage_comprehensive loads
- WHEN `get_entry` is called with `7.7.ccx_internal.image_registry_storage_comprehensive`
- THEN the title is `CCX image registry storage`
- AND `content_from` is `7.3.tsr.3_6_2_registry_storage_type`


### Requirement: KB 7.7.ccx_internal.tls_handshake_errors
`load_kb()` SHALL contain `7.7.ccx_internal.tls_handshake_errors` from `7_7_security.toml`. Title SHALL be `CCX TLS handshake errors`.

description SHALL be:

Cluster components are failing to establish secure (TLS) connections with each other. The evidence shows which components are affected. Common causes include expired certificates, mismatched TLS versions between components, or network appliances (load balancers, firewalls) interfering with encrypted traffic inside the cluster.

recommendation SHALL be:

TLS handshake failures between cluster components are usually expired certs, a too-strict TLS profile, or a middlebox terminating internal traffic. Identify the endpoints from the evidence, then check serving certs and the API TLS profile. Internal cluster TLS should pass through, not terminate, on the load balancer.

verification SHALL be:

1. Identify the failing components from the evidence log entries.
2. List TLS-related secrets for the affected namespace.
   `oc get secret -n <namespace> -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -E 'tls|cert|serving'`
3. Check the API server TLS security profile; a too-restrictive setting can cause handshake failures.
   `oc get apiserver cluster -o jsonpath='{.spec.tlsSecurityProfile}'`
4. If a load balancer or proxy sits between cluster nodes, confirm it passes through internal cluster TLS rather than terminating it.

impact SHALL be:

workload-shift

impact_scope SHALL be:

components failing TLS handshakes

impact_detail SHALL be:

Fixing handshake errors can require certificate rotation or TLS profile changes that restart the affected operands.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#tls-profiles-view-details_tls-security-profiles`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#tls-profiles-view-details_tls-security-profiles`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#tls-profiles-view-details_tls-security-profiles`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#tls-profiles-view-details_tls-security-profiles`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#tls-profiles-view-details_tls-security-profiles`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#tls-profiles-view-details_tls-security-profiles`.

#### Scenario: 7.7.ccx_internal.tls_handshake_errors loads
- WHEN `get_entry` is called with `7.7.ccx_internal.tls_handshake_errors`
- THEN the title is `CCX TLS handshake errors`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_1_security
`load_kb()` SHALL contain `7.7.tsr.7_1_security` from `7_7_security.toml`. Title SHALL be `7.1. Security`.

description SHALL be:

Parent section covering cluster security posture including container security,
auditing, encryption, vulnerability scanning, TLS profiles, and pod security
admission. Comprehensive security requires addressing each sub-area.

recommendation SHALL be:

This section is security posture. Child recs cover container security, etcd encryption, and PSA. Do not invent a rebuild rec here.

verification SHALL be:

1. Print SecurityContextConstraints and their privilege settings.
   `oc get scc -o custom-columns=NAME:.metadata.name,PRIV:.allowPrivilegedContainer`
2. Print the configured identity providers.
   `oc get oauth cluster -o jsonpath='{.spec.identityProviders[*].name}{"\t"}{.spec.identityProviders[*].type}{"\n"}'`
3. Print the API server etcd encryption type. An empty result means encryption is not configured.
   `oc get apiserver cluster -o jsonpath='{.spec.encryption.type}{"\n"}'`
4. Print Pod Security Admission enforce labels per namespace.
   `oc get namespaces -o custom-columns=NAME:.metadata.name,ENFORCE:.metadata.labels.pod-security\.kubernetes\.io/enforce`
5. Review individual sub-check findings for specific security concerns.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#security-platform_security-platform`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#security-platform_security-platform`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#security-platform_security-platform`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#security-platform_security-platform`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#security-platform_security-platform`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#security-platform_security-platform`.

#### Scenario: 7.7.tsr.7_1_security loads
- WHEN `get_entry` is called with `7.7.tsr.7_1_security`
- THEN the title is `7.1. Security`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_1_1_container_security
`load_kb()` SHALL contain `7.7.tsr.7_1_1_container_security` from `7_7_security.toml`. Title SHALL be `7.1.1. Container Security`.

description SHALL be:

Evaluates container security context constraints usage, privileged container
prevalence, and root user execution. Containers running with elevated
privileges increase the blast radius of a compromise.

recommendation SHALL be:

Pods on `privileged` or `anyuid` SCC widen blast radius. List those pods, then see whether they can move to `restricted-v2`. SCC privilege flags are the policy; the annotation on the pod is what actually applied.

verification SHALL be:

1. List pods running under the privileged or anyuid SCC.
   `oc get pods -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,SCC:.metadata.annotations.openshift\.io/scc --no-headers | awk '$3=="privileged" || $3=="anyuid" {print}'`
2. Evaluate whether those pods can move to `restricted-v2`.
3. Print the privilege flags for each SCC.
   `oc get scc -o custom-columns=NAME:.metadata.name,PRIV:.allowPrivilegedContainer,ALLOWPRIVESC:.allowPrivilegeEscalation,RUNAS:.runAsUser.type`

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads using the privileged SCC

impact_detail SHALL be:

Revoking privileged SCC access often requires pod rollout or manifest changes so workloads can start under a less-privileged policy.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/authentication_and_authorization/index#security-context-constraints-about_configuring-internal-oauth`.

#### Scenario: 7.7.tsr.7_1_1_container_security loads
- WHEN `get_entry` is called with `7.7.tsr.7_1_1_container_security`
- THEN the title is `7.1.1. Container Security`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_1_2_auditing
`load_kb()` SHALL contain `7.7.tsr.7_1_2_auditing` from `7_7_security.toml`. Title SHALL be `7.1.2. Auditing`.

`content_from` SHALL be `7.6.apiserver.audit` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.tsr.7_1_2_auditing loads
- WHEN `get_entry` is called with `7.7.tsr.7_1_2_auditing`
- THEN the title is `7.1.2. Auditing`
- AND `content_from` is `7.6.apiserver.audit`


### Requirement: KB 7.7.tsr.7_1_4_encrypting_data
`load_kb()` SHALL contain `7.7.tsr.7_1_4_encrypting_data` from `7_7_security.toml`. Title SHALL be `7.1.4. Encrypting data`.

description SHALL be:

Evaluates etcd encryption configuration for secrets and other sensitive
resources. Without etcd encryption at rest, anyone with access to etcd
backups or disk can read secrets in plaintext.

recommendation SHALL be:

Empty `spec.encryption` means etcd stores Secrets in plaintext on disk and in backups. `aesgcm` is the preferred type. Enabling encryption rolls API servers and migrates resources — watch conditions, do not assume it is instant.

verification SHALL be:

1. Print the API server encryption configuration.
   `oc get apiserver cluster -o jsonpath='{.spec.encryption}'`
2. If `spec.encryption` is empty, secrets are stored unencrypted. Enable encryption with `aesgcm` (preferred) or `aescbc`.
   `oc patch apiserver cluster --type=merge -p '{"spec":{"encryption":{"type":"aesgcm"}}}'`
3. Monitor the encryption migration progress.
   `oc get openshiftapiserver cluster -o jsonpath='{.status.conditions}'`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

API server and etcd encryption migration

impact_detail SHALL be:

Enabling etcd encryption triggers API server rollout and a background migration to encrypt all existing Secret objects, which takes time proportional to object count.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#encrypting-etcd_encrypting-etcd`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#encrypting-etcd_encrypting-etcd`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#encrypting-etcd_encrypting-etcd`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#encrypting-etcd_encrypting-etcd`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#encrypting-etcd_encrypting-etcd`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#encrypting-etcd_encrypting-etcd`.

#### Scenario: 7.7.tsr.7_1_4_encrypting_data loads
- WHEN `get_entry` is called with `7.7.tsr.7_1_4_encrypting_data`
- THEN the title is `7.1.4. Encrypting data`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_1_5_vulnerability_scanning
`load_kb()` SHALL contain `7.7.tsr.7_1_5_vulnerability_scanning` from `7_7_security.toml`. Title SHALL be `7.1.5. Vulnerability Scanning`.

description SHALL be:

Checks whether container image vulnerability scanning is configured and
active. Without scanning, vulnerable base images and application dependencies
remain undetected in the cluster.

recommendation SHALL be:

Without image scanning, CVEs in running containers stay invisible. Confirm a scanner is actually running (internal or external). Mirror/ICSP objects are how disconnected clusters still pull scanned content, not a scanner by themselves.

verification SHALL be:

1. Check for image-mirror configuration (ImageDigestMirrorSet, ImageTagMirrorSet, ImageContentSourcePolicy). Their presence indicates a disconnected or mirrored setup.
   `oc get imagedigestmirrorset,imagetagmirrorset,imagecontentsourcepolicy`
2. If using an external scanner, confirm scanning pods are running.
3. List unique container images running in the cluster.
   `oc get pods -A -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' | sort -u`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

image scanner (internal or external)

impact_detail SHALL be:

Standing up a scanner adds scan load. It does not reboot nodes. Mirror and ICSP are not a scanner.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/registry/index#images-allow-pods-to-reference-images-from-secure-registries_using-image-pull-secrets`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/registry/index#images-allow-pods-to-reference-images-from-secure-registries_using-image-pull-secrets`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/registry/index#images-allow-pods-to-reference-images-from-secure-registries_using-image-pull-secrets`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/registry/index#images-allow-pods-to-reference-images-from-secure-registries_using-image-pull-secrets`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/registry/index#images-allow-pods-to-reference-images-from-secure-registries_using-image-pull-secrets`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/registry/index#images-allow-pods-to-reference-images-from-secure-registries_using-image-pull-secrets`.

#### Scenario: 7.7.tsr.7_1_5_vulnerability_scanning loads
- WHEN `get_entry` is called with `7.7.tsr.7_1_5_vulnerability_scanning`
- THEN the title is `7.1.5. Vulnerability Scanning`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_1_6_tls_security_profiles
`load_kb()` SHALL contain `7.7.tsr.7_1_6_tls_security_profiles` from `7_7_security.toml`. Title SHALL be `7.1.6. TLS Security Profiles`.

`content_from` SHALL be `7.6.apiserver.tls` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.tsr.7_1_6_tls_security_profiles loads
- WHEN `get_entry` is called with `7.7.tsr.7_1_6_tls_security_profiles`
- THEN the title is `7.1.6. TLS Security Profiles`
- AND `content_from` is `7.6.apiserver.tls`


### Requirement: KB 7.7.tsr.7_1_7_pod_security_admission
`load_kb()` SHALL contain `7.7.tsr.7_1_7_pod_security_admission` from `7_7_security.toml`. Title SHALL be `7.1.7. Pod Security Admission`.

description SHALL be:

Evaluates Pod Security Admission (PSA) label enforcement across namespaces.
PSA replaces PodSecurityPolicy and provides namespace-level enforcement of
pod security standards (privileged, baseline, restricted).

recommendation SHALL be:

PSA labels on the namespace are what block privileged pods at admit time. Production should enforce at least `baseline`, preferably `restricted`. Relabeling does not evict already-running pods.

verification SHALL be:

1. Print the Pod Security Admission enforce label for each namespace.
   `oc get namespaces -o custom-columns=NAME:.metadata.name,ENFORCE:.metadata.labels.pod-security\.kubernetes\.io/enforce`
2. Production namespaces should enforce at least `baseline` or `restricted`.
3. Apply the enforce label where needed.
   `oc label ns <ns> pod-security.kubernetes.io/enforce=restricted --overwrite`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

namespace admission enforcement

impact_detail SHALL be:

PSA label changes affect admission for new or updated pods but do not restart existing pods or reboot nodes.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/authentication_and_authorization/index#understanding-and-managing-pod-security-admission`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/authentication_and_authorization/index#understanding-and-managing-pod-security-admission`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/authentication_and_authorization/index#understanding-and-managing-pod-security-admission`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/authentication_and_authorization/index#understanding-and-managing-pod-security-admission`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/authentication_and_authorization/index#understanding-and-managing-pod-security-admission`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/authentication_and_authorization/index#understanding-and-managing-pod-security-admission`.

#### Scenario: 7.7.tsr.7_1_7_pod_security_admission loads
- WHEN `get_entry` is called with `7.7.tsr.7_1_7_pod_security_admission`
- THEN the title is `7.1.7. Pod Security Admission`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_2_compliance
`load_kb()` SHALL contain `7.7.tsr.7_2_compliance` from `7_7_security.toml`. Title SHALL be `7.2. Compliance`.

description SHALL be:

Parent section covering compliance assessment including automated scanning,
scan results analysis, and file integrity monitoring. Compliance posture
requires continuous validation against organizational security baselines.

recommendation SHALL be:

This section is Compliance Operator plus File Integrity Operator. Child recs cover scan cadence, results, and FIO. Do not invent a rebuild rec here.

verification SHALL be:

1. Check whether the Compliance Operator is installed.
   `oc get csv -n openshift-compliance`
2. Check whether the File Integrity Operator is installed.
   `oc get csv -n openshift-file-integrity`
3. Confirm scan schedules and results show continuous compliance monitoring is active.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#compliance-operator-scan-management`.

#### Scenario: 7.7.tsr.7_2_compliance loads
- WHEN `get_entry` is called with `7.7.tsr.7_2_compliance`
- THEN the title is `7.2. Compliance`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_2_1_compliance_check
`load_kb()` SHALL contain `7.7.tsr.7_2_1_compliance_check` from `7_7_security.toml`. Title SHALL be `7.2.1. Compliance Check`.

description SHALL be:

Evaluates whether the Compliance Operator is installed and active with
configured scan schedules. Without automated compliance scanning, security
drift goes undetected between manual audits.

recommendation SHALL be:

No ScanSetting and no scheduled ComplianceSuite means scanning is not actually on. A running operator CSV is not enough — confirm a suite against CIS, NIST, or STIG.

verification SHALL be:

1. Confirm the Compliance Operator pods are running.
   `oc get pods -n openshift-compliance`
2. List the configured `ScanSettings`.
   `oc get scansettings -n openshift-compliance`
3. Confirm at least one `ComplianceSuite` is scheduled against a relevant profile (`CIS`, `NIST`, or `STIG`).

impact SHALL be:

non-disruptive

impact_scope SHALL be:

Compliance Operator ScanSetting and suite

impact_detail SHALL be:

Deploying the Compliance Operator and running scans adds cluster load and creates scan pods, but it does not reboot nodes by itself.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#compliance-operator-scan-management`.

#### Scenario: 7.7.tsr.7_2_1_compliance_check loads
- WHEN `get_entry` is called with `7.7.tsr.7_2_1_compliance_check`
- THEN the title is `7.2.1. Compliance Check`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_2_1_1_compliance_scans
`load_kb()` SHALL contain `7.7.tsr.7_2_1_1_compliance_scans` from `7_7_security.toml`. Title SHALL be `7.2.1.1. Compliance Scans`.

description SHALL be:

Checks ComplianceScan execution status and schedule. Scans that are not running
or have stale last-run timestamps indicate the compliance monitoring pipeline
is broken or misconfigured.

recommendation SHALL be:

Scans should be DONE or RUNNING. Stale or failed PHASE means the pipeline is broken. Check scanner pod logs before you re-create the suite.

verification SHALL be:

1. List ComplianceScans and verify each shows phase `DONE` or `RUNNING`.
   `oc get compliancescan -n openshift-compliance -o custom-columns=NAME:.metadata.name,PHASE:.status.phase`
2. Print the ComplianceSuite schedule and phase.
   `oc get compliancesuite -n openshift-compliance -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,SCHEDULE:.spec.schedule`
3. Investigate any failed or stale scans by checking the scanner pod logs.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

scanner pods

impact_detail SHALL be:

Deploying the Compliance Operator and running scans adds cluster load and creates scan pods, but it does not reboot nodes by itself.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#compliance-operator-scan-management`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#compliance-operator-scan-management`.

#### Scenario: 7.7.tsr.7_2_1_1_compliance_scans loads
- WHEN `get_entry` is called with `7.7.tsr.7_2_1_1_compliance_scans`
- THEN the title is `7.2.1.1. Compliance Scans`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_2_1_2_compliance_scan_results
`load_kb()` SHALL contain `7.7.tsr.7_2_1_2_compliance_scan_results` from `7_7_security.toml`. Title SHALL be `7.2.1.2. Compliance Scan Results`.

description SHALL be:

Evaluates ComplianceCheckResult objects for **FAIL** and INCONSISTENT findings.
Failed compliance checks indicate configuration drift from the target security
baseline and may have regulatory implications.

recommendation SHALL be:

Failed and inconsistent ComplianceCheckResults are drift from the chosen profile. Read the rule, then the remediation — applying a remediation can roll nodes.

verification SHALL be:

1. List ComplianceCheckResults with a **FAIL** status.
   `oc get compliancecheckresults -n openshift-compliance -o custom-columns=NAME:.metadata.name,STATUS:.status --no-headers | awk '$2=="FAIL" {print}'`
2. List available ComplianceRemediations for the failed rules.
   `oc get complianceremediations -n openshift-compliance`
3. Apply remediations only after reviewing their impact; some roll nodes.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes targeted by the remediation

impact_detail SHALL be:

Applying a Compliance remediation can drain and reboot targeted nodes. Read the rule before you apply it.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#compliance-operator-remediation`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#compliance-operator-remediation`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#compliance-operator-remediation`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#compliance-operator-remediation`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#compliance-operator-remediation`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#compliance-operator-remediation`.

#### Scenario: 7.7.tsr.7_2_1_2_compliance_scan_results loads
- WHEN `get_entry` is called with `7.7.tsr.7_2_1_2_compliance_scan_results`
- THEN the title is `7.2.1.2. Compliance Scan Results`
- AND `content_from` is empty


### Requirement: KB 7.7.tsr.7_2_2_file_integrity
`load_kb()` SHALL contain `7.7.tsr.7_2_2_file_integrity` from `7_7_security.toml`. Title SHALL be `7.2.2. File Integrity`.

description SHALL be:

Evaluates File Integrity Operator deployment and monitoring status. File
integrity monitoring detects unauthorized changes to critical system files
on cluster nodes, which may indicate compromise or configuration drift.

recommendation SHALL be:

File Integrity Operator watches host paths for unexpected change. FAILED FileIntegrityNodeStatus is the finding. Confirm FIO covers `/etc`, `/boot`, and `/usr/lib/systemd` before you treat silence as clean.

verification SHALL be:

1. List File Integrity Operator resources.
   `oc get fileintegrity -A`
2. Print FileIntegrityNodeStatus across all namespaces.
   `oc get fileintegritynodestatuses -A`
3. Investigate nodes showing `FAILED` status by reviewing the list of changed files.
4. Confirm FIO is monitoring critical paths including `/etc`, `/boot`, and `/usr/lib/systemd`.

impact SHALL be:

non-disruptive

impact_scope SHALL be:

File Integrity Operator node status

impact_detail SHALL be:

FAILED FileIntegrityNodeStatus is investigation first. Reverting host files through MachineConfig drains and reboots that pool.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#file-integrity-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/security_and_compliance/index#file-integrity-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/security_and_compliance/index#file-integrity-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/security_and_compliance/index#file-integrity-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/security_and_compliance/index#file-integrity-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/security_and_compliance/index#file-integrity-operator`.

#### Scenario: 7.7.tsr.7_2_2_file_integrity loads
- WHEN `get_entry` is called with `7.7.tsr.7_2_2_file_integrity`
- THEN the title is `7.2.2. File Integrity`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.unsupported_cni_plugin
`load_kb()` SHALL contain `7.7.ccx_internal.unsupported_cni_plugin` from `7_7_security.toml`. Title SHALL be `CCX Unsupported CNI Plugin`.

description SHALL be:

Cluster network provider TYPE. OVNKubernetes is **PASS**. OpenShiftSDN is **FAIL** (removed in 4.17). Any other TYPE is **FAIL** unsupported.

recommendation SHALL be:

Supported CNI is OVNKubernetes on both spec and status. OpenShiftSDN was removed in 4.17 and must not remain. Anything else is unsupported.

verification SHALL be:

1. Print the network type from spec and status (network.config cluster). Both showing OVNKubernetes is healthy; OpenShiftSDN or any other type needs action.
   `oc get network.config cluster --no-headers -o custom-columns=SPEC:.spec.networkType,STATUS:.status.networkType | awk '{r="FAIL"; if($1=="OVNKubernetes" && $2=="OVNKubernetes") r="PASS"; print r, "SPEC="$1, "STATUS="$2}'`
2. Print the operator defaultNetwork type (network.operator cluster). It must match the spec; OVNKubernetes is healthy.
   `oc get network.operator cluster --no-headers -o custom-columns=TYPE:.spec.defaultNetwork.type | awk '{r="FAIL"; if($1=="OVNKubernetes") r="PASS"; print r, "TYPE="$1}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

cluster networking

impact_detail SHALL be:

Supported CNI is OVNKubernetes. Changing networkType in place is a rebuild, not a day-2 patch.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#about-ovn-kubernetes`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#about-ovn-kubernetes`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#about-ovn-kubernetes`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#about-ovn-kubernetes`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#about-ovn-kubernetes`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#about-ovn-kubernetes`.

#### Scenario: 7.7.ccx_internal.unsupported_cni_plugin loads
- WHEN `get_entry` is called with `7.7.ccx_internal.unsupported_cni_plugin`
- THEN the title is `CCX Unsupported CNI Plugin`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.cluster_status_overview
`load_kb()` SHALL contain `7.7.ccx_internal.cluster_status_overview` from `7_7_security.toml`. Title SHALL be `CCX Cluster Status Overview`.

description SHALL be:

Insights provides a high-level cluster status assessment covering overall health
indicators. This CCX check aggregates multiple signals into a single cluster
health determination.

recommendation SHALL be:

This is a live cross-check of Insights cluster-health against ClusterOperators, nodes, and ClusterVersion. Confirm the reported issue is still true before you plan work from a stale Insights row.

verification SHALL be:

1. Cross-check the Insights cluster status against live state.
   `oc get co`
   `oc get nodes`
   `oc get clusterversion`
2. Compare the Insights finding with current conditions to confirm whether the reported issues persist.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#about-remote-health-monitoring_about-remote-health-monitoring`.

#### Scenario: 7.7.ccx_internal.cluster_status_overview loads
- WHEN `get_entry` is called with `7.7.ccx_internal.cluster_status_overview`
- THEN the title is `CCX Cluster Status Overview`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.cluster_status_overview_machines
`load_kb()` SHALL contain `7.7.ccx_internal.cluster_status_overview_machines` from `7_7_security.toml`. Title SHALL be `CCX Cluster Status Overview Machines`.

description SHALL be:

Insights detected machine-level issues including failed provisioning, stuck
deletions, or machines not matching their MachineSet desired state.

recommendation SHALL be:

Machines not Running are a provisioner/BMC/quota problem, not the scheduler. Empty MachineSets on UPI are often N/A. Inspect PHASE and machine-api logs before you scale the MachineSet.

verification SHALL be:

1. List all Machines and their phase.
   `oc get machines -A`
2. Filter for Machines not in Running phase. Any listed row needs investigation.
   `oc get machines -A --no-headers -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase | awk '$3!="Running" {print}'`
3. Investigate reported Machines by checking machine-api operator logs.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

infrastructure provider (quota, PXE, BMC)

impact_detail SHALL be:

Bringing MachineSet available count to desired is provisioner work, not the scheduler. Empty MachineSets on UPI are often not applicable.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/machine_management/index#machine-mgmt-intro-managing-compute_overview-of-machine-management`.

#### Scenario: 7.7.ccx_internal.cluster_status_overview_machines loads
- WHEN `get_entry` is called with `7.7.ccx_internal.cluster_status_overview_machines`
- THEN the title is `CCX Cluster Status Overview Machines`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.cluster_status_overview_networks
`load_kb()` SHALL contain `7.7.ccx_internal.cluster_status_overview_networks` from `7_7_security.toml`. Title SHALL be `CCX Cluster Status Overview Networks`.

description SHALL be:

Insights detected networking configuration issues or degraded network operator
status that may affect pod-to-pod communication or external connectivity.

recommendation SHALL be:

Degraded `co/network` or a non-OVN type is cluster-wide connectivity risk. Print the operator, the networkType, then OVN pods.

verification SHALL be:

1. Check the network ClusterOperator health. Available True with Degraded and Progressing False is healthy.
   `oc get co network --no-headers | awk '{print ($3=="True" && $4=="False" && $5=="False"?"PASS":"FAIL"), $0}'`
2. Print the network type.
   `oc get network.config cluster -o jsonpath='{.spec.networkType}'`
3. List OVN-Kubernetes pods.
   `oc get pods -n openshift-ovn-kubernetes`

impact SHALL be:

workload-shift

impact_scope SHALL be:

OVN-Kubernetes pods and cluster networking

impact_detail SHALL be:

Restoring the network ClusterOperator rolls OVN pods and can interrupt east-west traffic. Do not change networkType in place.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking_overview/index#about-openshift-sdn`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/networking_overview/index#about-openshift-sdn`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/networking_overview/index#about-openshift-sdn`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/networking_overview/index#about-openshift-sdn`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/networking_overview/index#about-openshift-sdn`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/networking_overview/index#about-openshift-sdn`.

#### Scenario: 7.7.ccx_internal.cluster_status_overview_networks loads
- WHEN `get_entry` is called with `7.7.ccx_internal.cluster_status_overview_networks`
- THEN the title is `CCX Cluster Status Overview Networks`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.cluster_status_overview_nodes_and_machineconfigpools
`load_kb()` SHALL contain `7.7.ccx_internal.cluster_status_overview_nodes_and_machineconfigpools` from `7_7_security.toml`. Title SHALL be `CCX Cluster Status Overview Nodes And Machineconfigpools`.

description SHALL be:

Insights detected issues with node readiness or `MachineConfigPool` degradation.
NotReady nodes cannot schedule workloads; degraded MCPs block configuration
rollout and upgrades.

recommendation SHALL be:

NotReady nodes cannot schedule; a degraded MCP blocks MachineConfig and upgrades. Describe the node or pool before you unpause or drain.

verification SHALL be:

1. List nodes and `MachineConfigPool`s.
   `oc get nodes`
   `oc get mcp`
2. Investigate any `NotReady` nodes.
   `oc describe node <node>`
3. For degraded MCPs, inspect the pool details and MCO logs.
   `oc describe mcp <pool>`
4. Common causes include failed kubelet restarts, disk pressure, or stalled MachineConfig rendering.

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the degraded or updating MachineConfigPool

impact_detail SHALL be:

Resolving MCP degradation may require the MCO to drain and reboot stuck nodes to complete configuration rollout.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`.

#### Scenario: 7.7.ccx_internal.cluster_status_overview_nodes_and_machineconfigpools loads
- WHEN `get_entry` is called with `7.7.ccx_internal.cluster_status_overview_nodes_and_machineconfigpools`
- THEN the title is `CCX Cluster Status Overview Nodes And Machineconfigpools`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.cluster_status_overview_operators
`load_kb()` SHALL contain `7.7.ccx_internal.cluster_status_overview_operators` from `7_7_security.toml`. Title SHALL be `CCX Cluster Status Overview Operators`.

`content_from` SHALL be `7.5.tsr.5_3_operator_state` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.cluster_status_overview_operators loads
- WHEN `get_entry` is called with `7.7.ccx_internal.cluster_status_overview_operators`
- THEN the title is `CCX Cluster Status Overview Operators`
- AND `content_from` is `7.5.tsr.5_3_operator_state`


### Requirement: KB 7.7.ccx_internal.image_registry_pods
`load_kb()` SHALL contain `7.7.ccx_internal.image_registry_pods` from `7_7_security.toml`. Title SHALL be `CCX Image Registry Pods`.

`content_from` SHALL be `7.5.tsr.5_4_registry_health` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.image_registry_pods loads
- WHEN `get_entry` is called with `7.7.ccx_internal.image_registry_pods`
- THEN the title is `CCX Image Registry Pods`
- AND `content_from` is `7.5.tsr.5_4_registry_health`


### Requirement: KB 7.7.ccx_internal.master_nodes_are_schedulable
`load_kb()` SHALL contain `7.7.ccx_internal.master_nodes_are_schedulable` from `7_7_security.toml`. Title SHALL be `CCX Master Nodes Are Schedulable`.

`content_from` SHALL be `7.1.tsr.1_4_1_5_master_schedulable` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.master_nodes_are_schedulable loads
- WHEN `get_entry` is called with `7.7.ccx_internal.master_nodes_are_schedulable`
- THEN the title is `CCX Master Nodes Are Schedulable`
- AND `content_from` is `7.1.tsr.1_4_1_5_master_schedulable`


### Requirement: KB 7.7.ccx_internal.node_ip_does_not_match_machine_network
`load_kb()` SHALL contain `7.7.ccx_internal.node_ip_does_not_match_machine_network` from `7_7_security.toml`. Title SHALL be `CCX Node IP Does Not Match Machine Network`.

description SHALL be:

Node InternalIP vs install-config machineNetwork. Inside a MACHINE CIDR is **PASS**. Outside is **FAIL**. Missing ConfigMap is **INFO** n/a-install-config. No CIDRs is **INFO** n/a-machine-network. No InternalIP is **INFO** n/a-node-ip.

recommendation SHALL be:

Each node InternalIP should sit in install-config `machineNetwork`. An address outside that CIDR is a day-0 addressing problem. Missing install-config or CIDRs means you cannot prove the match from this capture.

verification SHALL be:

1. Confirm the install-config ConfigMap exists. If not found, the machine network cannot be verified from this source.
   `oc get cm cluster-config-v1 -n kube-system`
2. Print each node name and InternalIP. If the list is empty, no node IPs were found.
   `oc get nodes --no-headers -o custom-columns='NAME:.metadata.name,INTERNALIP:.status.addresses[?(@.type=="InternalIP")].address' | awk 'NF{print "INFO", "NAME="$1, "INTERNALIP="$2} END{if(NR==0) print "INFO n/a-node-ip"}'`
3. Print machineNetwork CIDRs from the install-config. If the list is empty, no machine network is configured.
   `oc get cm cluster-config-v1 -n kube-system -o jsonpath='{.data.install-config}' | awk '$1=="machineNetwork:"{in_block=1; next} in_block && /cidr:/{print "INFO", "MACHINE="$NF; n++; next} in_block && $1 ~ /^[a-zA-Z]/{in_block=0} END{if(!n) print "INFO n/a-machine-network"}'`
4. For each node IP, compare it against a machineNetwork CIDR from step 3. Inside the range is healthy; outside needs action.
   `python3 -c 'import ipaddress,sys; ip=sys.argv[1]; cidr=sys.argv[2]; print("PASS" if ipaddress.ip_address(ip) in ipaddress.ip_network(cidr, strict=False) else "FAIL")' <INTERNALIP> <MACHINE>`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

node addressing versus install-config machineNetwork

impact_detail SHALL be:

Node IPs outside the CIDR are a day-0 addressing problem. Do not patch Infrastructure to hide it.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-network-connectivity-user-infra_installing-platform-agnostic`.

#### Scenario: 7.7.ccx_internal.node_ip_does_not_match_machine_network loads
- WHEN `get_entry` is called with `7.7.ccx_internal.node_ip_does_not_match_machine_network`
- THEN the title is `CCX Node IP Does Not Match Machine Network`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.node_requirements_internal
`load_kb()` SHALL contain `7.7.ccx_internal.node_requirements_internal` from `7_7_security.toml`. Title SHALL be `CCX Node Requirements Internal`.

description SHALL be:

Documented node floors: control-plane 4 vCPU and 16 GiB, worker 2 vCPU and 8 GiB.

recommendation SHALL be:

Documented floors: control-plane 4 vCPU / 16 GiB, worker 2 vCPU / 8 GiB. Score each field separately. On compact clusters the worker-role nodes are the masters — use the master floors.

verification SHALL be:

1. Print control-plane node CPU count. 4 or more is healthy. If the list is empty, no master-role nodes exist.
   `oc get nodes -l node-role.kubernetes.io/master --no-headers -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu | awk '{print ($2+0>=4?"PASS":"FAIL"), "NAME="$1, "CPU="$2} END{if(NR==0) print "INFO n/a-master-cpu"}'`
2. Print control-plane node memory. 16 GiB (16777216 Ki) or more is healthy. If the list is empty, no master-role nodes exist.
   `oc get nodes -l node-role.kubernetes.io/master --no-headers -o custom-columns=NAME:.metadata.name,MEM:.status.capacity.memory | awk '{print ($2+0>=16777216?"PASS":"FAIL"), "NAME="$1, "MEM="$2} END{if(NR==0) print "INFO n/a-master-mem"}'`
3. Print worker-role node CPU count. 2 or more is healthy. If the list is empty, no worker-role nodes exist.
   `oc get nodes -l node-role.kubernetes.io/worker --no-headers -o custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu | awk '{print ($2+0>=2?"PASS":"FAIL"), "NAME="$1, "CPU="$2} END{if(NR==0) print "INFO n/a-worker-cpu"}'`
4. Print worker-role node memory. 8 GiB (8388608 Ki) or more is healthy. If the list is empty, no worker-role nodes exist.
   `oc get nodes -l node-role.kubernetes.io/worker --no-headers -o custom-columns=NAME:.metadata.name,MEM:.status.capacity.memory | awk '{print ($2+0>=8388608?"PASS":"FAIL"), "NAME="$1, "MEM="$2} END{if(NR==0) print "INFO n/a-worker-mem"}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

undersized control-plane or worker nodes

impact_detail SHALL be:

Resize or replace any undersized control-plane node. That work requires a maintenance window and can reduce API capacity while a master is remediated.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_any_platform/index#installation-minimum-resource-requirements_installing-platform-agnostic`.

#### Scenario: 7.7.ccx_internal.node_requirements_internal loads
- WHEN `get_entry` is called with `7.7.ccx_internal.node_requirements_internal`
- THEN the title is `CCX Node Requirements Internal`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.pods_check
`load_kb()` SHALL contain `7.7.ccx_internal.pods_check` from `7_7_security.toml`. Title SHALL be `CCX Pods Check`.

description SHALL be:

Red Hat Insights found pods that are not in a healthy Running or Completed state. This includes pods stuck in Pending, `CrashLoopBackOff`, Error, or other abnormal states. The evidence lists the affected pods and their status.

recommendation SHALL be:

Treat pods that are not Running or successfully Completed as an active workload-health finding and investigate the underlying cause before deleting or restarting them. Start with pod events, then review current logs to identify the failure reason. Resolve Pending pods by validating scheduling constraints, namespace quotas, PVC binding, image pulls, node capacity and pressure, and required configuration or secrets. Resolve `CrashLoopBackOff` and Error states by correcting the application, configuration, dependency, or resource issue identified in the logs. Delete a pod only after collecting evidence and fixing the root cause, as deletion alone commonly recreates the same failure.

verification SHALL be:

1. List pods not in Running or Completed state.
   `oc get pods -A | grep -Ev 'Running|Completed'`
2. For each problem pod, check events and the previous container log for the failure reason.
   `oc describe pod <pod> -n <ns>`
   `oc logs <pod> -n <ns> --previous`
3. Common causes include OOMKilled (resource limits too low), missing ConfigMaps or Secrets, image pull failures, or node resource exhaustion.

impact SHALL be:

workload-shift

impact_scope SHALL be:

pods that are not Running or successfully Completed

impact_detail SHALL be:

Fixing scheduling, quota, PVC, image pull, or application config starts or restarts those pods.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/support/index#investigating-pod-issues`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/support/index#investigating-pod-issues`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/support/index#investigating-pod-issues`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/support/index#investigating-pod-issues`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/support/index#investigating-pod-issues`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/support/index#investigating-pod-issues`.

#### Scenario: 7.7.ccx_internal.pods_check loads
- WHEN `get_entry` is called with `7.7.ccx_internal.pods_check`
- THEN the title is `CCX Pods Check`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.version_check
`load_kb()` SHALL contain `7.7.ccx_internal.version_check` from `7_7_security.toml`. Title SHALL be `CCX Version Check`.

`content_from` SHALL be `7.1.tsr.1_1_identification_and_state` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.version_check loads
- WHEN `get_entry` is called with `7.7.ccx_internal.version_check`
- THEN the title is `CCX Version Check`
- AND `content_from` is `7.1.tsr.1_1_identification_and_state`


### Requirement: KB 7.7.ccx_internal.version_info
`load_kb()` SHALL contain `7.7.ccx_internal.version_info` from `7_7_security.toml`. Title SHALL be `CCX Version Info`.

description SHALL be:

Insights version information check providing details about the cluster version,
update channel, and available updates. This informational check helps track
cluster currency and update availability.

recommendation SHALL be:

Version, channel, and availableUpdates are currency, not a defect by themselves. Confirm the channel matches the support policy.

verification SHALL be:

1. Print the cluster version, update channel, and available updates.
   `oc get clusterversion version -o jsonpath='{.status.desired.version}{" "}{.spec.channel}{"\n"}{range .status.availableUpdates[*]}available={.version}{"\n"}{end}'`
   `oc adm upgrade`
2. Verify the cluster is on a supported update channel.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#understanding-openshift-updates`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#understanding-openshift-updates`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#understanding-openshift-updates`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#understanding-openshift-updates`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#understanding-openshift-updates`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#understanding-openshift-updates`.

#### Scenario: 7.7.ccx_internal.version_info loads
- WHEN `get_entry` is called with `7.7.ccx_internal.version_info`
- THEN the title is `CCX Version Info`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_external.mcp_set_to_pause
`load_kb()` SHALL contain `7.7.ccx_external.mcp_set_to_pause` from `7_7_security.toml`. Title SHALL be `MCP Set To Pause`.

description SHALL be:

This check is the named `MachineConfigPool` degraded, updating, paused, and machine-count posture. `Updated=False` with matching `updatedMachineCount` and `readyMachineCount` and `spec.paused=true` is a pause hold, not a missing node count. Degraded or mismatched counts are a rollout defect.

recommendation SHALL be:

Bring the named `MachineConfigPool` to a stable rollout: `Degraded=False`, not stuck `Updating`, and `spec.paused=false` unless a documented canary or change window requires a short pause. A paused pool with matching machine counts is an intentional hold, not a missing update. Unpause only after that window; the Machine Config Operator then drains and often reboots remaining nodes, and a long pause can block kube-apiserver-to-kubelet CA rotation so `oc debug` and `oc exec` fail. If machine counts do not match or `Degraded` is True, inspect pool conditions and Machine Config Daemon logs on the affected nodes before changing `paused` or `maxUnavailable`.

verification SHALL be:

1. List each pool name, paused flag, and machine counts. Paused true with matching counts is the pause case. Mismatched counts or Degraded need investigation.
   `oc get mcp`
2. Print paused on each pool. True needs a documented window or unpause.
   `oc get mcp -o custom-columns=NAME:.metadata.name,PAUSED:.spec.paused`
3. If Degraded is True, print the condition reason and message.
   `oc describe mcp <pool>`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

nodes in the named MachineConfigPool

impact_detail SHALL be:

Unpausing or repairing a pool lets the MCO drain and reboot nodes in that pool.

`finding_group` SHALL be `mcp-paused`.

`finding_group_title` SHALL be `MachineConfigPool paused`.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/postinstallation_configuration/index#understanding-the-machine-config-operator`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/machine_configuration/index#understanding-the-machine-config-operator`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/machine_configuration/index#understanding-the-machine-config-operator`.

#### Scenario: 7.7.ccx_external.mcp_set_to_pause loads
- WHEN `get_entry` is called with `7.7.ccx_external.mcp_set_to_pause`
- THEN the title is `MCP Set To Pause`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.machine_pool_check
`load_kb()` SHALL contain `7.7.ccx_internal.machine_pool_check` from `7_7_security.toml`. Title SHALL be `Machine Pool Check`.

`content_from` SHALL be `7.5.tsr.5_7_machine_config_pool` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.machine_pool_check loads
- WHEN `get_entry` is called with `7.7.ccx_internal.machine_pool_check`
- THEN the title is `Machine Pool Check`
- AND `content_from` is `7.5.tsr.5_7_machine_config_pool`


### Requirement: KB 7.7.ccx_external.cluster_does_not_support_olm_operators_network_policies
`load_kb()` SHALL contain `7.7.ccx_external.cluster_does_not_support_olm_operators_network_policies` from `7_7_security.toml`. Title SHALL be `Cluster Does Not Support OLM Operators Network Policies`.

description SHALL be:

Red Hat Insights reports this OpenShift z-stream cannot let Operator Lifecycle Manager manage `NetworkPolicy` objects for OLM components. The defect is platform OLM support (Insights Fixed Version), not a missing customer NetworkPolicy.

recommendation SHALL be:

Upgrade the cluster to the Insights **Fixed Version** or a later z-stream on the same minor so OLM can manage its own `NetworkPolicy` objects. Do not create or edit NetworkPolicies for OLM namespaces to clear this finding; those objects are platform-managed after the z-stream. Use `oc adm upgrade` to pick an approved target that is at least the Fixed Version.

verification SHALL be:

1. Print the current ClusterVersion. Compare it to the Fixed Version in Observation. Below that z-stream needs an upgrade.
   `oc get clusterversion version -o jsonpath='{.status.desired.version}{"\n"}'`
2. List eligible updates. Pick a target at or above the Fixed Version.
   `oc adm upgrade`

impact SHALL be:

rolling-restart

impact_scope SHALL be:

control plane and worker nodes in unpaused MachineConfigPools

impact_detail SHALL be:

The z-stream upgrade rolls operators and typically reboots nodes through the MCO.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index#understanding-openshift-updates`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/updating_clusters/index#understanding-openshift-updates`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#understanding-openshift-updates`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/updating_clusters/index#understanding-openshift-updates`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/updating_clusters/index#understanding-openshift-updates`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/updating_clusters/index#understanding-openshift-updates`.

#### Scenario: 7.7.ccx_external.cluster_does_not_support_olm_operators_network_policies loads
- WHEN `get_entry` is called with `7.7.ccx_external.cluster_does_not_support_olm_operators_network_policies`
- THEN the title is `Cluster Does Not Support OLM Operators Network Policies`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_external.ocp_version_end_of_life
`load_kb()` SHALL contain `7.7.ccx_external.ocp_version_end_of_life` from `7_7_security.toml`. Title SHALL be `OCP Version End Of Life`.

description SHALL be:

Insights `OCP4X_EOL_IMMINENT` (or past EOL) compares ClusterVersion to the OpenShift life-cycle calendar. Even-numbered minors are EUS releases; Maintenance end is not the same as “no EUS remaining.”

recommendation SHALL be:

Confirm whether the subscription includes Extended Update Support for this even-numbered minor. After Maintenance ends, Full/Maintenance patches stop; EUS Term 1 (when entitled) continues Critical/Important and urgent fixes only. Plan an EUS-to-EUS or supported minor upgrade off the assessed z-stream. A same-minor z-stream after Maintenance end does not restore Full/Maintenance. Do not stay on an unelected Standard-tier minor past Maintenance without an EUS add-on.

verification SHALL be:

1. Print desired version and channel.
   `oc get clusterversion version -o jsonpath='{.status.desired.version}{" "}{.spec.channel}{"\n"}'`
2. Compare the minor to the OpenShift Container Platform life-cycle page in the reference for this check (Maintenance vs EUS dates).

impact SHALL be:

maintenance-window

impact_scope SHALL be:

entire cluster

impact_detail SHALL be:

Leaving Maintenance without EUS or an upgrade path leaves the cluster without standard errata; the upgrade itself reboots nodes.

Links SHALL be `default` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.18` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.19` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.20` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.21` -> `https://access.redhat.com/support/policy/updates/openshift`, `4.22` -> `https://access.redhat.com/support/policy/updates/openshift`.

#### Scenario: 7.7.ccx_external.ocp_version_end_of_life loads
- WHEN `get_entry` is called with `7.7.ccx_external.ocp_version_end_of_life`
- THEN the title is `OCP Version End Of Life`
- AND `content_from` is empty


### Requirement: KB 7.7.ccx_internal.pods_crash_loop_check
`load_kb()` SHALL contain `7.7.ccx_internal.pods_crash_loop_check` from `7_7_security.toml`. Title SHALL be `Pods Crash Loop Check`.

`content_from` SHALL be `7.5.pods.crashloop` and the row SHALL NOT carry its own description, recommendation, verification, impact, or links.

#### Scenario: 7.7.ccx_internal.pods_crash_loop_check loads
- WHEN `get_entry` is called with `7.7.ccx_internal.pods_crash_loop_check`
- THEN the title is `Pods Crash Loop Check`
- AND `content_from` is `7.5.pods.crashloop`


### Requirement: KB 7.8.etcd.leader_changes
`load_kb()` SHALL contain `7.8.etcd.leader_changes` from `7_8_metrics.toml`. Title SHALL be `etcd leader changes`.

description SHALL be:

Frequent etcd leader elections indicate instability, often caused by disk
latency, network timeouts, or control plane resource contention. Excessive
leader churn affects write availability and overall control plane stability.

recommendation SHALL be:

Fix the disk or network causing etcd leader elections; do not restart etcd. Zero in the last hour is healthy. One to three is worth a look; more than three is unstable leadership. Check WAL fsync first.

verification SHALL be:

1. Leader change count (etcd_server_leader_changes_seen_total) summed over one hour. Zero is **PASS**, 1-3 is **INFO**, above 3 is **WARNING**. An empty result means the metric is not scraped:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=sum(increase(etcd_server_leader_changes_seen_total[1h]))' | jq -r 'if (.data.result|length)==0 then "n/a" else .data.result[0].value[1] end' | awk '{if($1=="n/a") print "INFO n/a-leader-changes"; else {c=$1+0; r="PASS"; if(c>3) r="WARNING"; else if(c>0) r="INFO"; printf "%s CHANGES=%.0f\n", r, c}}'`
2. Per-member leader changes showing which pod saw the election:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=increase(etcd_server_leader_changes_seen_total[1h])' | jq -r '.data.result[] | [.metric.pod // "-", .value[1]] | @tsv' | awk '{printf "POD=%s CHANGES=%.0f\n", $1, $2+0} END{if(NR==0) print "INFO n/a-leader-changes"}'`
3. If step 1 printed **INFO** or **WARNING**, check etcd member logs for election entries:
   `oc -n openshift-etcd logs etcd-<member> -c etcd --since=1h | grep 'elected leader'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane nodes and etcd storage path

impact_detail SHALL be:

Fixing etcd disk-performance problems usually requires control-plane infrastructure or storage changes that can reduce API capacity while nodes are remediated.

Links SHALL be `default` -> `https://access.redhat.com/solutions/4885641`, `4.18` -> `https://access.redhat.com/solutions/4885641`, `4.19` -> `https://access.redhat.com/solutions/4885641`, `4.20` -> `https://access.redhat.com/solutions/4885641`, `4.21` -> `https://access.redhat.com/solutions/4885641`, `4.22` -> `https://access.redhat.com/solutions/4885641`.

#### Scenario: 7.8.etcd.leader_changes loads
- WHEN `get_entry` is called with `7.8.etcd.leader_changes`
- THEN the title is `etcd leader changes`
- AND `content_from` is empty


### Requirement: KB 7.8.etcd.wal*
`load_kb()` SHALL contain `7.8.etcd.wal*` from `7_8_metrics.toml`. Title SHALL be `etcd WAL fsync latency`.

The row SHALL be a glob pattern.

description SHALL be:

etcd WAL fsync latency directly impacts write throughput and leader elections.
P99 latency above 10 ms is a documented FAIL. Use NVMe or enterprise SSD for etcd.

recommendation SHALL be:

Move etcd onto NVMe or enterprise SSD when WAL fsync P99 is above 10 ms. Do not retune etcd to hide slow disks. A missing metric means WAL latency was not scraped. Backend commit and peer RTT are correlation only.

verification SHALL be:

1. WAL fsync P99 latency per etcd member (etcd_disk_wal_fsync_duration_seconds). At or below 10 ms is **PASS**, above 10 ms is **FAIL**. An empty result means the metric is not scraped:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m]))' | jq -r '.data.result[] | [.metric.pod // "-", .value[1]] | @tsv' | awk '{if($2=="NaN"||$2=="+Inf"||$2=="-Inf"){print "INFO", "POD="$1, "P99=n/a-nan"; next} ms=$2*1000; r="PASS"; if(ms>10) r="FAIL"; printf "%s POD=%s P99=%.1fms\n", r, $1, ms} END{if(NR==0) print "INFO n/a-wal"}'`
2. Backend commit latency and peer round-trip time for correlation only:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=histogram_quantile(0.99, rate(etcd_disk_backend_commit_duration_seconds_bucket[5m]))' | jq -r '.data.result[] | [.metric.pod // "-", .value[1]] | @tsv' | awk '{if($2=="NaN"||$2=="+Inf"||$2=="-Inf"){print "INFO", "POD="$1, "BACKEND_P99=n/a-nan"; next} printf "POD=%s BACKEND_P99=%.1fms\n", $1, $2*1000} END{if(NR==0) print "INFO n/a-backend"}'`
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket[2m]))' | jq -r '.data.result[] | [.metric.pod // "-", .value[1]] | @tsv' | awk '{if(!seen[$1]++) printf "POD=%s RTT=%.1fms\n", $1, $2*1000} END{if(NR==0) print "INFO n/a-rtt"}'`
3. Etcd member endpoint status across the cluster:
   `oc -n openshift-etcd exec -c etcd etcd-<member> -- etcdctl endpoint status --cluster -w table`
4. Ensure etcd nodes use NVMe or enterprise SSD and dedicate a partition for `/var/lib/etcd` on bare metal.
5. If latency stays elevated, validate the storage subsystem with `quay.io/cloud-bulldozer/etcd-perf` before planning remediation.

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane nodes and etcd storage path

impact_detail SHALL be:

Fixing etcd disk-performance problems usually requires control-plane infrastructure or storage changes that can reduce API capacity while nodes are remediated.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/scalability_and_performance/recommended-performance-and-scalability-practices-2`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/scalability_and_performance/recommended-performance-and-scalability-practices-2`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index`.

#### Scenario: 7.8.etcd.wal* loads
- WHEN `get_entry` is called with `7.8.etcd.wal*`
- THEN the title is `etcd WAL fsync latency`
- AND `content_from` is empty


### Requirement: KB 7.8.etcd.proposals
`load_kb()` SHALL contain `7.8.etcd.proposals` from `7_8_metrics.toml`. Title SHALL be `etcd failed proposals`.

description SHALL be:

Failed raft proposals indicate that some write requests could not be committed.
This usually points to a slow or failed cluster member, or disk/network
latency affecting quorum progress.

recommendation SHALL be:

Fix the slow member or disk causing failed raft proposals; do not restart etcd. Zero is healthy. Any failed proposal is a write-path problem. Check WAL fsync before treating a member as dead.

verification SHALL be:

1. Failed proposal count (etcd_server_proposals_failed_total) summed over one hour. Zero is **PASS**, above zero is **WARNING**. An empty result means the metric is not scraped:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=sum(increase(etcd_server_proposals_failed_total[1h]))' | jq -r 'if (.data.result|length)==0 then "n/a" else .data.result[0].value[1] end' | awk '{if($1=="n/a") print "INFO n/a-proposals"; else {c=$1+0; r="PASS"; if(c>0) r="WARNING"; printf "%s FAILED=%.0f\n", r, c}}'`
2. Per-member failed proposals showing which pod dropped writes:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=increase(etcd_server_proposals_failed_total[1h])' | jq -r '.data.result[] | [.metric.pod // "-", .value[1]] | @tsv' | awk '{printf "POD=%s FAILED=%.0f\n", $1, $2+0} END{if(NR==0) print "INFO n/a-proposals"}'`
3. If step 1 printed **WARNING**, list firing etcd leader-change and gRPC-slow alerts. An empty result means no relevant alerts are active:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=ALERTS{alertname=~"etcdHighNumberOfLeaderChanges|etcdGRPCRequestsSlow"}' | jq -r '.data.result[] | [.metric.alertname // "-", .metric.pod // "-", .metric.alertstate // "-"] | @tsv' | awk '{print "WARNING", "ALERT="$1, "POD="$2, "STATE="$3} END{if(NR==0) print "PASS none-firing"}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane nodes and etcd storage path

impact_detail SHALL be:

Fixing etcd disk-performance problems usually requires control-plane infrastructure or storage changes that can reduce API capacity while nodes are remediated.

Links SHALL be `default` -> `https://etcd.io/docs/latest/tuning/`, `4.18` -> `https://etcd.io/docs/latest/tuning/`, `4.19` -> `https://etcd.io/docs/latest/tuning/`, `4.20` -> `https://etcd.io/docs/latest/tuning/`, `4.21` -> `https://etcd.io/docs/latest/tuning/`, `4.22` -> `https://etcd.io/docs/latest/tuning/`.

#### Scenario: 7.8.etcd.proposals loads
- WHEN `get_entry` is called with `7.8.etcd.proposals`
- THEN the title is `etcd failed proposals`
- AND `content_from` is empty


### Requirement: KB 7.8.apiserver.latency
`load_kb()` SHALL contain `7.8.apiserver.latency` from `7_8_metrics.toml`. Title SHALL be `API server latency`.

description SHALL be:

This check's verification bar treats API server P99 latency above 500 ms as a warning (timeouts in kubelet, controller-manager, and scheduler) and above 1000 ms as an API incident. Investigate etcd slowness, control plane resource exhaustion, and excessive API churn.

recommendation SHALL be:

Fix etcd disk or webhook timeouts when API server P99 is over 500 ms; do not change API flags first. The finding is the slowest RESOURCE/VERB pair; WATCH and CONNECT are excluded. Over 500 ms is slow; over 1000 ms is an API incident. Skip the follow-up command when P99 is already healthy.

verification SHALL be:

1. Slowest API resource/verb pair by P99 latency (`topk(1, … > 0)`). At or below 500 ms is **PASS**, above 500 ms is **WARNING**, above 1000 ms is **FAIL**. An empty result means no resource latency is available:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=topk(1, histogram_quantile(0.99, sum(rate(apiserver_request_duration_seconds_bucket{scope="resource",verb!~"WATCH|CONNECT"}[5m])) by (le, resource, verb)) > 0)' | jq -r '.data.result[] | [.metric.resource, .metric.verb, .value[1]] | @tsv' | awk '{ms=$3*1000; r="PASS"; if(ms>1000) r="FAIL"; else if(ms>500) r="WARNING"; print r, "RESOURCE="$1, "VERB="$2, "P99="int(ms+0.5)"ms"} END{if(NR==0) print "INFO n/a-apiserver-latency"}'`
2. Only if step 1 printed **WARNING** or **FAIL**, list remaining pairs above 500 ms (`… > 0.5`). An empty result means only the top pair was slow:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=histogram_quantile(0.99, sum(rate(apiserver_request_duration_seconds_bucket{scope="resource",verb!~"WATCH|CONNECT"}[5m])) by (le, resource, verb)) > 0.5' | jq -r '.data.result[] | [.metric.resource, .metric.verb, .value[1]] | @tsv' | awk '{ms=$3*1000; r="WARNING"; if(ms>1000) r="FAIL"; print r, "RESOURCE="$1, "VERB="$2, "P99="int(ms+0.5)"ms"} END{if(NR==0) print "PASS none-slow"}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

etcd disk or admission webhooks

impact_detail SHALL be:

Fixing etcd disk-performance problems usually requires control-plane infrastructure or storage changes that can reduce API capacity while nodes are remediated. Webhook timeout or Fail policy is an API-object change and does not reboot nodes.

Links SHALL be `default` -> `https://raw.githubusercontent.com/kubernetes/community/master/sig-scalability/slos/api_call_latency.md`.

#### Scenario: 7.8.apiserver.latency loads
- WHEN `get_entry` is called with `7.8.apiserver.latency`
- THEN the title is `API server latency`
- AND `content_from` is empty


### Requirement: KB 7.8.pvc.util.critical
`load_kb()` SHALL contain `7.8.pvc.util.critical` from `7_8_metrics.toml`. Title SHALL be `PVC utilization critical`.

description SHALL be:

PVCs above 90% utilization are at immediate risk of filling completely, which
causes application errors, data loss, or pod eviction. Expand or migrate
immediately before the volume reaches 100%.

recommendation SHALL be:

Expand or migrate PVCs over 90% used before ENOSPC. Expand in place only if the StorageClass allows it; otherwise migrate. Online resize can still restart the pod. Any such claim needs action now.

verification SHALL be:

1. PVCs over 90% utilization (kubelet_volume_stats_used_bytes / capacity). Any listed row is **FAIL**. An empty result means no claim exceeds 90%:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=round(kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * 100, 1) > 90' | jq -r '.data.result[] | [.metric.namespace, .metric.persistentvolumeclaim, .value[1]] | @tsv' | awk -F'\t' '{print "FAIL", "NS="$1, "PVC="$2, "USED="int($3)"%"} END{if(NR==0) print "PASS none-critical"}'`
2. For each listed PVC, print phase, capacity, request size, and StorageClass:
   `oc get pvc <name> -n <ns> -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,REQUEST:.spec.resources.requests.storage,SC:.spec.storageClassName`
3. Pods mounting the affected PVC. These workloads will hit ENOSPC if the volume fills:
   `oc get pod -n <ns> --no-headers -o custom-columns=POD:.metadata.name,PVC:.spec.volumes[*].persistentVolumeClaim.claimName | awk -v claim='<name>' '$0 ~ claim {print "POD="$1, "PVC="$2}'`
4. StorageClass volume expansion support. `EXPAND=true` can grow in place; `EXPAND=false` requires migration:
   `oc get sc -o custom-columns=NAME:.metadata.name,EXPAND:.allowVolumeExpansion --no-headers | awk '{print "NAME="$1, "EXPAND="$2}'`
5. Firing KubePersistentVolumeFillingUp alert. Any listed row needs action. An empty result means the alert is not firing:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | select(.labels.alertname=="KubePersistentVolumeFillingUp") | [.state, .labels.namespace, .labels.persistentvolumeclaim, .labels.severity] | @tsv' | awk -F'\t' '{print "FAIL", "STATE="$1, "NS="$2, "PVC="$3, "SEVERITY="$4} END{if(NR==0) print "INFO n/a-fillingup-alert"}'`
6. If expansion is supported, patch the PVC size (resize starts after patch). Otherwise migrate to a larger volume:
   `oc patch pvc <name> -n <ns> -p '{"spec":{"resources":{"requests":{"storage":"<new-size>"}}}}'`
7. After patching, confirm FileSystemResizePending clears and capacity matches the request:
   `oc get pvc <name> -n <ns> -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'`

impact SHALL be:

workload-shift

impact_scope SHALL be:

workloads mounted to the affected PVC

impact_detail SHALL be:

Online expansion may be transparent, but storage migration or cutover can require pod restart, rescheduling, or temporary workload movement.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`.

#### Scenario: 7.8.pvc.util.critical loads
- WHEN `get_entry` is called with `7.8.pvc.util.critical`
- THEN the title is `PVC utilization critical`
- AND `content_from` is empty


### Requirement: KB 7.8.pvc.util.warning
`load_kb()` SHALL contain `7.8.pvc.util.warning` from `7_8_metrics.toml`. Title SHALL be `PVC utilization warning`.

description SHALL be:

PVCs between 75% and 90% used may fill during peak load. Plan expansion or migration before the claim reaches the 90% critical band.

recommendation SHALL be:

Plan expansion or migration for PVCs in the 75–90% band before they hit 90%. Any row in this band needs a dated plan.

verification SHALL be:

1. PVCs between 75% and 90% utilization. Any listed row is **WARNING**. An empty result means no claim is in the warning band:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -sG http://localhost:9090/api/v1/query --data-urlencode 'query=(round(kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * 100, 1) > 75) unless (round(kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes * 100, 1) > 90)' | jq -r '.data.result[] | [.metric.namespace, .metric.persistentvolumeclaim, .value[1]] | @tsv' | awk -F'\t' '{print "WARNING", "NS="$1, "PVC="$2, "USED="int($3)"%"} END{if(NR==0) print "PASS none-warning"}'`
2. For each listed PVC, print phase, capacity, request size, and StorageClass:
   `oc get pvc <name> -n <ns> -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,REQUEST:.spec.resources.requests.storage,SC:.spec.storageClassName`
3. Pods mounting the affected PVC:
   `oc get pod -n <ns> --no-headers -o custom-columns=POD:.metadata.name,PVC:.spec.volumes[*].persistentVolumeClaim.claimName | awk -v claim='<name>' '$0 ~ claim {print "POD="$1, "PVC="$2}'`
4. StorageClass volume expansion support. `EXPAND=true` can grow in place; `EXPAND=false` requires migration:
   `oc get sc -o custom-columns=NAME:.metadata.name,EXPAND:.allowVolumeExpansion --no-headers | awk '{print "NAME="$1, "EXPAND="$2}'`
5. Firing KubePersistentVolumeFillingUp alert. A firing row usually means the claim crossed 90%. An empty result means the alert is not firing:
   `oc -n openshift-monitoring exec prometheus-k8s-0 -c prometheus -- curl -s http://localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | select(.labels.alertname=="KubePersistentVolumeFillingUp") | [.state, .labels.namespace, .labels.persistentvolumeclaim, .labels.severity] | @tsv' | awk -F'\t' '{print "WARNING", "STATE="$1, "NS="$2, "PVC="$3, "SEVERITY="$4} END{if(NR==0) print "INFO n/a-fillingup-alert"}'`
6. Schedule expansion during a maintenance window. If expansion is supported, patch the PVC. Otherwise plan migration before usage crosses 90%:
   `oc patch pvc <name> -n <ns> -p '{"spec":{"resources":{"requests":{"storage":"<new-size>"}}}}'`
7. After patching, confirm FileSystemResizePending clears and capacity matches the request:
   `oc get pvc <name> -n <ns> -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'`

impact SHALL be:

non-disruptive

impact_scope SHALL be:

affected PVC-backed workloads

impact_detail SHALL be:

Proactive expansion is often online when the StorageClass supports it; only backend migrations or unsupported expansion paths require workload movement.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#expanding-csi-volumes_expanding-persistent-volumes`.

#### Scenario: 7.8.pvc.util.warning loads
- WHEN `get_entry` is called with `7.8.pvc.util.warning`
- THEN the title is `PVC utilization warning`
- AND `content_from` is empty


### Requirement: KB 7.8.pvc.util.ok
`load_kb()` SHALL contain `7.8.pvc.util.ok` from `7_8_metrics.toml`. Title SHALL be `PVC utilization normal`.

description SHALL be:

This check's verification bar is PVC capacity under 75% used. Continue monitoring for sustained growth trends and confirm expansion procedures are documented.

recommendation SHALL be:

Keep PVCs under 75% and confirm StorageClass expansion now so you are not inventing a process at 90%. This is the healthy band, not a skip on capacity planning.

verification SHALL be:

1. All PVCs listed by namespace. This is informational while usage stays under 75%:
   `oc get pvc -A`
2. StorageClass volume expansion support. Confirm `EXPAND=true` before you need it:
   `oc get sc -o custom-columns=NAME:.metadata.name,EXPAND:.allowVolumeExpansion`
3. Review growth trends so expansion can be planned before any PVC reaches the 75% warning band.

impact SHALL be:

none

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/storage/index#expanding-persistent-volumes`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/storage/index#expanding-persistent-volumes`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/storage/index#expanding-persistent-volumes`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/storage/index#expanding-persistent-volumes`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/storage/index#expanding-persistent-volumes`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/storage/index#expanding-persistent-volumes`.

#### Scenario: 7.8.pvc.util.ok loads
- WHEN `get_entry` is called with `7.8.pvc.util.ok`
- THEN the title is `PVC utilization normal`
- AND `content_from` is empty


### Requirement: KB 7.9.hw.*.identity
`load_kb()` SHALL contain `7.9.hw.*.identity` from `7_9_hardware.toml`. Title SHALL be `Hardware Identity`.

description SHALL be:

Server vendor, model, and BIOS version provide context for hardware support,
firmware advisories, and capacity planning. Verifying these details against the
vendor support matrix ensures the platform runs on certified hardware.

recommendation SHALL be:

Record vendor, product, and BIOS against the catalog. A catalog miss is not a cluster defect; it means the SKU is undocumented. On metal, `BareMetalHost` `status.hardware` is the live object — do not dump the BMH YAML (BMC credentials live there). No BMH means this is not a metal cluster; then read DMI via `oc debug`. Firmware is a host replace or update window, not an `oc` patch.

verification SHALL be:

1. Server identity from `BareMetalHost` (status.hardware.systemVendor). Each row prints **INFO** with vendor, product, and BIOS version. An empty result means the CRD is absent or this is not bare metal:
   `oc get bmh -A -o json 2>/dev/null | jq -r '.items[]? | [.metadata.name, (.status.hardware.systemVendor.manufacturer // "-"), (.status.hardware.systemVendor.productName // "-"), (.status.hardware.firmware.bios.version // "-"), (.status.hardware.firmware.bios.date // "-")] | @tsv' | awk -F'\t' '{print "INFO", "NAME="$1, "VENDOR="$2, "PRODUCT="$3, "BIOS="$4, "BIOSDATE="$5} END{if(NR==0) print "INFO n/a-bmh"}'`
2. If step 1 returned no results, read DMI identity directly on the node:
   `oc debug node/<name> --quiet -- chroot /host sh -c 'printf "VENDOR="; cat /sys/class/dmi/id/sys_vendor; printf "PRODUCT="; cat /sys/class/dmi/id/product_name; printf "BIOS="; cat /sys/class/dmi/id/bios_version; printf "BIOSDATE="; cat /sys/class/dmi/id/bios_date'`
3. Compare the product name to the Red Hat certified hardware catalog using the link in the reference.
4. Compare the BIOS version to the vendor firmware advisory for that product.

impact SHALL be:

none

Links SHALL be `default` -> `https://catalog.redhat.com/hardware`, `4.18` -> `https://catalog.redhat.com/hardware`, `4.21` -> `https://catalog.redhat.com/hardware`, `4.22` -> `https://catalog.redhat.com/hardware`.

#### Scenario: 7.9.hw.*.identity loads
- WHEN `get_entry` is called with `7.9.hw.*.identity`
- THEN the title is `Hardware Identity`
- AND `content_from` is empty


### Requirement: KB 7.9.hw.*.cpu
`load_kb()` SHALL contain `7.9.hw.*.cpu` from `7_9_hardware.toml`. Title SHALL be `CPU`.

description SHALL be:

CPU model and core count determine the node's compute capacity. Control plane
nodes require a minimum of 4 vCPUs; worker nodes should be sized according to
the expected workload profile.

recommendation SHALL be:

Resize or replace the node if you need more cores. This is live CPU capacity, not the 4 vCPU install floor. On metal, `BareMetalHost` `status.hardware.cpu` is the live object — do not dump the BMH YAML. No BMH means this is not a metal cluster; then read `/proc` via `oc debug`. `oc adm top` is usage, not capacity.

verification SHALL be:

1. CPU details from `BareMetalHost` (status.hardware.cpu). Each row prints **INFO** with model, core count, and architecture. An empty result means the CRD is absent or this is not bare metal:
   `oc get bmh -A -o json 2>/dev/null | jq -r '.items[]? | [.metadata.name, (.status.hardware.cpu.model // "-"), (.status.hardware.cpu.count // "-"), (.status.hardware.cpu.arch // "-")] | @tsv' | awk -F'\t' '{print "INFO", "NAME="$1, "MODEL="$2, "CORES="$3, "ARCH="$4} END{if(NR==0) print "INFO n/a-bmh"}'`
2. If step 1 returned no results, read CPU model and logical core count on the node:
   `oc debug node/<name> --quiet -- chroot /host grep -m1 'model name' /proc/cpuinfo`
   `oc debug node/<name> --quiet -- chroot /host grep -c ^processor /proc/cpuinfo`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

the node being resized or replaced

impact_detail SHALL be:

Resizing or replacing a node to add CPU requires a maintenance window and may involve node drain, reinstallation, or host replacement.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`.

#### Scenario: 7.9.hw.*.cpu loads
- WHEN `get_entry` is called with `7.9.hw.*.cpu`
- THEN the title is `CPU`
- AND `content_from` is empty


### Requirement: KB 7.9.hw.*.memory
`load_kb()` SHALL contain `7.9.hw.*.memory` from `7_9_hardware.toml`. Title SHALL be `Memory`.

description SHALL be:

Physical RAM determines the node's memory capacity. Control plane nodes require
a minimum of 16 GiB; worker nodes should be sized for the expected workload
footprint including kubelet, container runtime, and application pods.

recommendation SHALL be:

Resize or replace the node if you need more RAM. This is live memory capacity, not the 16 GiB install floor. On metal, `BareMetalHost` `status.hardware.ramMebibytes` is the live object — do not dump the BMH YAML. No BMH means this is not a metal cluster; then read MemTotal via `oc debug`. `oc adm top` is usage, not capacity.

verification SHALL be:

1. RAM from `BareMetalHost` (status.hardware.ramMebibytes). Each row prints **INFO** with total memory in GiB. An empty result means the CRD is absent or this is not bare metal:
   `oc get bmh -A -o json 2>/dev/null | jq -r '.items[]? | [.metadata.name, (.status.hardware.ramMebibytes // 0)] | @tsv' | awk -F'\t' '{printf "INFO NAME=%s RAM_GIB=%.1f\n", $1, $2/1024} END{if(NR==0) print "INFO n/a-bmh"}'`
2. If step 1 returned no results, read MemTotal on the node:
   `oc debug node/<name> --quiet -- chroot /host awk '/MemTotal/{printf "RAM_GIB=%.1f\n", $2/1024/1024}' /proc/meminfo`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

the node being resized or replaced

impact_detail SHALL be:

Resizing or replacing a node to add memory requires a maintenance window and may involve node drain, reinstallation, or host replacement.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/installing_on_bare_metal/index#installation-requirements-user-infra_installing-bare-metal`.

#### Scenario: 7.9.hw.*.memory loads
- WHEN `get_entry` is called with `7.9.hw.*.memory`
- THEN the title is `Memory`
- AND `content_from` is empty


### Requirement: KB 7.9.hw.*.disk
`load_kb()` SHALL contain `7.9.hw.*.disk` from `7_9_hardware.toml`. Title SHALL be `Disk`.

description SHALL be:

Disk type and capacity affect cluster performance and supportability. Rotational
(HDD) storage causes etcd latency and raft timeouts on control plane nodes.
SSD or NVMe storage is strongly recommended for all nodes, especially those
running etcd.

recommendation SHALL be:

Replace rotational disks when lsblk shows `ROTA=1` and TRAN is not virtio. Guest ROTA on virtio is not a maintenance-window HDD swap. `BareMetalHost` ROTA is the guest flag, not the hypervisor backing store. Empty BMH means this is not a metal cluster. Do not dump BMH YAML (BMC).

verification SHALL be:

1. Guest rotational flag from `BareMetalHost` (status.hardware.storage). `ROTA=true` is the guest-advertised flag, not proof of a physical HDD; a virtio disk name indicates KVM. An empty result means the CRD is absent or this is not bare metal:
   `oc get bmh -A -o json 2>/dev/null | jq -r '.items[]? | .metadata.name as $n | (.status.hardware.storage // [])[] | [$n, (.name // "-"), ((.rotational|tostring) // "-"), (.sizeBytes // 0), (.type // "-")] | @tsv' | awk -F'\t' '{tag="n/a-guest-rota"; if($2 ~ /virtio/) tag="n/a-virtio-rota"; r="PASS"; if($3=="true") r="INFO " tag; printf "%s NAME=%s DISK=%s GUEST_ROTA=%s SIZE_GIB=%.0f TYPE=%s\n", r, $1, $2, $3, $4/1024/1024/1024, $5} END{if(NR==0) print "INFO n/a-bmh"}'`
2. Actual disk media via lsblk on the node. `ROTA=0` is **PASS**. `ROTA=1` with `TRAN=virtio` is **INFO** (guest flag only). `ROTA=1` with any other transport is **WARNING**:
   `oc debug node/<name> --quiet -- chroot /host lsblk -d -o NAME,SIZE,ROTA,TYPE,TRAN -n -e 7,11 | awk '{r="PASS"; if($3=="1" && $5=="virtio") r="INFO n/a-virtio-rota"; else if($3=="1") r="WARNING"; print r, "DISK="$1, "SIZE="$2, "ROTA="$3, "TYPE="$4, "TRAN="$5} END{if(NR==0) print "INFO n/a-disks"}'`

impact SHALL be:

maintenance-window

impact_scope SHALL be:

control plane storage and etcd performance

impact_detail SHALL be:

Replacing rotational storage with SSD/NVMe on control plane nodes requires a maintenance window and may involve node drain, reinstallation, or disk migration.

Links SHALL be `default` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.18` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/scalability_and_performance/index#etcd-verify-hardware_recommended-etcd-practices`, `4.19` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.20` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.21` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html-single/etcd/index#etcd-verify-hardware_etcd-practices`, `4.22` -> `https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html-single/etcd/index#etcd-verify-hardware_etcd-practices`.

#### Scenario: 7.9.hw.*.disk loads
- WHEN `get_entry` is called with `7.9.hw.*.disk`
- THEN the title is `Disk`
- AND `content_from` is empty

