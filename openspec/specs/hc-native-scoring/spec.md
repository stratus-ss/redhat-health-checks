# Native scoring

## Purpose

Status matrices for native evaluators on `main`, extracted from the evaluator audit and corrected by `hc-report-engine` where that spec is newer. TSR and CCX catalog expansion stays in `hc-report-engine`. An empty Prometheus vector that emits no row is not a SKIPPED placeholder.

## Requirements

### Requirement: Registry order and empty categories
Core evaluation SHALL run categories in this order: `03_base_platform`, `04_topology`, `05_components`, `06_layered`, `07_cluster_health`, `08_day2`, `09_security`, `10_metrics`, `11_hardware`. An empty category folder SHALL emit `{chapter}.category` with status `SKIPPED` and evidence `Category not collected`. Floors are 4 CPU and 16 GiB for control-plane nodes, 2 CPU and 8 GiB for other nodes, and 100 GiB disk. `_hc_error` and `_hc_not_found` are missing data.

#### Scenario: Empty category is skipped
- GIVEN `05_components` was not collected
- WHEN registry evaluation runs
- THEN `7.3.category` status is SKIPPED


### Requirement: Report engine overrides this catalog
Where `openspec/specs/hc-report-engine/spec.md` states a status for the same check, that requirement wins. Overrides include `7.1.nodes.master_sched`, `7.1.sys.fips`, `7.3.net.featuregates`, Virtualization Automatic approval, documented install minimums as FAIL, etcd WAL above 10 ms as FAIL, backend commit above 25 ms as INFO, absence of native 7.3 etcd metric placeholders 3.5.4 through 3.5.9, and a paused MachineConfigPool with matching counts as WARNING. The rows below are the 2026-08-25 evaluator catalog for every other check.

#### Scenario: Install floor override
- GIVEN a node is below the documented CPU, memory, or disk floor
- WHEN the matching 7.1 or 7.2 check runs
- THEN status is FAIL
- AND this catalog's older WARNING matrix does not apply


### Requirement: `7.1.subs.approval` and day-2 equivalent scoring
In Shared helpers, ``7.1.subs.approval` and day-2 equivalent` SHALL evaluate Subscription `spec.installPlanApproval`. Status matrix: Any subscription with `Automatic` → **WARNING**. Otherwise **PASS** (including zero Automatic).. Source function: ``_evaluate_approval_strategy``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.subs.approval` and day-2 equivalent matrix
- GIVEN collected data for ``7.1.subs.approval` and day-2 equivalent`
- WHEN the category evaluator runs
- THEN the status follows: Any subscription with `Automatic` → **WARNING**. Otherwise **PASS** (including zero Automatic).


### Requirement: `7.1.clusterversion.id` scoring
In 7.1 Base Platform, ``7.1.clusterversion.id`` SHALL evaluate Cluster ID, desired/history version, channel. Status matrix: Always **INFO**. Source function: ``_evaluate_cluster_version``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.clusterversion.id` matrix
- GIVEN collected data for ``7.1.clusterversion.id``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO**


### Requirement: `7.1.clusterversion.channel` scoring
In 7.1 Base Platform, ``7.1.clusterversion.channel`` SHALL evaluate `spec.channel` substring. Status matrix: Contains `stable` or `eus` → **PASS**. Contains `fast` or `candidate` → **WARNING**. Anything else → **WARNING** (unrecognised).. Source function: ``_evaluate_channel``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.clusterversion.channel` matrix
- GIVEN collected data for ``7.1.clusterversion.channel``
- WHEN the category evaluator runs
- THEN the status follows: Contains `stable` or `eus` → **PASS**. Contains `fast` or `candidate` → **WARNING**. Anything else → **WARNING** (unrecognised).


### Requirement: `7.1.clusterversion.updates` scoring
In 7.1 Base Platform, ``7.1.clusterversion.updates`` SHALL evaluate `status.availableUpdates`. Status matrix: Non-empty → **WARNING**. Empty → **PASS** (“latest for channel”). Source function: ``_evaluate_cluster_version``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.clusterversion.updates` matrix
- GIVEN collected data for ``7.1.clusterversion.updates``
- WHEN the category evaluator runs
- THEN the status follows: Non-empty → **WARNING**. Empty → **PASS** (“latest for channel”)


### Requirement: `7.1.clusterversion.history` scoring
In 7.1 Base Platform, ``7.1.clusterversion.history`` SHALL evaluate History entries with `state == Completed`. Status matrix: Any completed → **PASS**. None → **NOT_APPLICABLE**. Source function: ``_evaluate_cluster_version``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.clusterversion.history` matrix
- GIVEN collected data for ``7.1.clusterversion.history``
- WHEN the category evaluator runs
- THEN the status follows: Any completed → **PASS**. None → **NOT_APPLICABLE**


### Requirement: `7.1.clusterversion.failing` scoring
In 7.1 Base Platform, ``7.1.clusterversion.failing`` SHALL evaluate Condition `type == Failing` and `status == True`. Status matrix: Any → **FAIL**. Else **PASS**. Source function: ``_evaluate_cluster_version``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.clusterversion.failing` matrix
- GIVEN collected data for ``7.1.clusterversion.failing``
- WHEN the category evaluator runs
- THEN the status follows: Any → **FAIL**. Else **PASS**


### Requirement: `7.1.infra.platform` scoring
In 7.1 Base Platform, ``7.1.infra.platform`` SHALL evaluate Platform and infrastructure name. Status matrix: Always **INFO**. Source function: ``_evaluate_infrastructure``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.infra.platform` matrix
- GIVEN collected data for ``7.1.infra.platform``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO**


### Requirement: `7.1.infra.topology` scoring
In 7.1 Base Platform, ``7.1.infra.topology`` SHALL evaluate `controlPlaneTopology` and `infrastructureTopology` both `HighlyAvailable`. Status matrix: Both HA → **PASS**. Else **WARNING**. Source function: ``_evaluate_infrastructure``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.infra.topology` matrix
- GIVEN collected data for ``7.1.infra.topology``
- WHEN the category evaluator runs
- THEN the status follows: Both HA → **PASS**. Else **WARNING**


### Requirement: `7.1.infra.apiurl` scoring
In 7.1 Base Platform, ``7.1.infra.apiurl`` SHALL evaluate `apiServerURL`. Status matrix: Emitted only if URL non-empty; always **INFO**. If empty, **no check**.. Source function: ``_evaluate_infrastructure``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.infra.apiurl` matrix
- GIVEN collected data for ``7.1.infra.apiurl``
- WHEN the category evaluator runs
- THEN the status follows: Emitted only if URL non-empty; always **INFO**. If empty, **no check**.


### Requirement: `7.1.infra.vips` scoring
In 7.1 Base Platform, ``7.1.infra.vips`` SHALL evaluate API and/or ingress VIP from `platformStatus`. Status matrix: Emitted only if at least one VIP present; always **PASS**. If neither VIP, **no check**.. Source function: ``_evaluate_infrastructure``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.infra.vips` matrix
- GIVEN collected data for ``7.1.infra.vips``
- WHEN the category evaluator runs
- THEN the status follows: Emitted only if at least one VIP present; always **PASS**. If neither VIP, **no check**.


### Requirement: `7.1.infra.installer` scoring
In 7.1 Base Platform, ``7.1.infra.installer`` SHALL evaluate `install-config` YAML platform keys. Status matrix: No YAML → **SKIPPED**. Else **INFO** with UPI (`platform: none`) vs IPI cloud/baremetal labels. Source function: ``_evaluate_infrastructure_installer``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.infra.installer` matrix
- GIVEN collected data for ``7.1.infra.installer``
- WHEN the category evaluator runs
- THEN the status follows: No YAML → **SKIPPED**. Else **INFO** with UPI (`platform: none`) vs IPI cloud/baremetal labels


### Requirement: `7.1.infra.hypervisor` scoring
In 7.1 Base Platform, ``7.1.infra.hypervisor`` SHALL evaluate Infrastructure platform. Status matrix: `vsphere`, `ovirt`, `openstack`, `kubevirt` → **INFO**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_infrastructure_hypervisor``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.infra.hypervisor` matrix
- GIVEN collected data for ``7.1.infra.hypervisor``
- WHEN the category evaluator runs
- THEN the status follows: `vsphere`, `ovirt`, `openstack`, `kubevirt` → **INFO**. Else **NOT_APPLICABLE**


### Requirement: `7.1.infra.restricted` scoring
In 7.1 Base Platform, ``7.1.infra.restricted`` SHALL evaluate `imageContentSources` in install-config or proxy `trustedCA.name`. Status matrix: Always **INFO** (restricted vs connected wording). Source function: ``_evaluate_infrastructure_restricted``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.infra.restricted` matrix
- GIVEN collected data for ``7.1.infra.restricted``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO** (restricted vs connected wording)


### Requirement: `7.1.subs` scoring
In 7.1 Base Platform, ``7.1.subs`` SHALL evaluate Subscription list empty after flatten. Status matrix: **NOT_APPLICABLE** “No subscriptions found”. Source function: ``_evaluate_subscriptions``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.subs` matrix
- GIVEN collected data for ``7.1.subs``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE** “No subscriptions found”


### Requirement: `7.1.sub.{name}` scoring
In 7.1 Base Platform, ``7.1.sub.{name}`` SHALL evaluate Per-subscription state vs CSV phase. Status matrix: `AtLatestKnown` and CSV `Succeeded` or `Unknown` → **PASS**. Installed CSV ≠ current CSV → **WARNING**. CSV phase `Failed` → **FAIL**. State not in `AtLatestKnown` / `UpgradePending` / empty → **WARNING**. Else **PASS**.. Source function: ``_evaluate_single_subscription``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sub.{name}` matrix
- GIVEN collected data for ``7.1.sub.{name}``
- WHEN the category evaluator runs
- THEN the status follows: `AtLatestKnown` and CSV `Succeeded` or `Unknown` → **PASS**. Installed CSV ≠ current CSV → **WARNING**. CSV phase `Failed` → **FAIL**. State not in `AtLatestKnown` / `UpgradePending` / empty → **WARNING**. Else **PASS**.


### Requirement: `7.1.subs.approval` scoring
In 7.1 Base Platform, ``7.1.subs.approval`` SHALL evaluate Automatic vs Manual approval. Status matrix: See Shared helpers. Source function: ``_evaluate_approval_strategy``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.subs.approval` matrix
- GIVEN collected data for ``7.1.subs.approval``
- WHEN the category evaluator runs
- THEN the status follows: See Shared helpers


### Requirement: `7.1.nodes.os` scoring
In 7.1 Base Platform, ``7.1.nodes.os`` SHALL evaluate Node `osImage`. Status matrix: Every image contains `CoreOS` or `RHCOS` → **PASS**. Else **INFO**. Source function: ``_evaluate_nodes_os``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.nodes.os` matrix
- GIVEN collected data for ``7.1.nodes.os``
- WHEN the category evaluator runs
- THEN the status follows: Every image contains `CoreOS` or `RHCOS` → **PASS**. Else **INFO**


### Requirement: `7.1.nodes.master_cpu` scoring
In 7.1 Base Platform, ``7.1.nodes.master_cpu`` SHALL evaluate Master capacity CPU vs `_MASTER_MIN_CPU` (4). Status matrix: Any master below 4 → **WARNING**. Else **PASS**. Source function: ``_evaluate_master_cpu``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.nodes.master_cpu` matrix
- GIVEN collected data for ``7.1.nodes.master_cpu``
- WHEN the category evaluator runs
- THEN the status follows: Any master below 4 → **WARNING**. Else **PASS**


### Requirement: `7.1.nodes.master_mem` scoring
In 7.1 Base Platform, ``7.1.nodes.master_mem`` SHALL evaluate Master capacity memory vs `_MASTER_MIN_MEM_GIB` (16.0). Status matrix: Any below 16 GiB → **WARNING**. Else **PASS**. Source function: ``_evaluate_master_memory``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.nodes.master_mem` matrix
- GIVEN collected data for ``7.1.nodes.master_mem``
- WHEN the category evaluator runs
- THEN the status follows: Any below 16 GiB → **WARNING**. Else **PASS**


### Requirement: `7.1.nodes.master_disk` scoring
In 7.1 Base Platform, ``7.1.nodes.master_disk`` SHALL evaluate Max sysinfo disk or ephemeral-storage vs `_MIN_DISK_GIB` (100). Status matrix: Any below 100 GiB → **WARNING**. Else **PASS**. Source function: ``_evaluate_master_disk``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.nodes.master_disk` matrix
- GIVEN collected data for ``7.1.nodes.master_disk``
- WHEN the category evaluator runs
- THEN the status follows: Any below 100 GiB → **WARNING**. Else **PASS**


### Requirement: `7.1.nodes.master_sched` scoring
In 7.1 Base Platform, ``7.1.nodes.master_sched`` SHALL evaluate `scheduler.spec.mastersSchedulable` (default True if missing). Status matrix: Always **PASS** (wording changes; status does not). Source function: ``_evaluate_master_schedulable``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.nodes.master_sched` matrix
- GIVEN collected data for ``7.1.nodes.master_sched``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS** (wording changes; status does not)


### Requirement: `7.1.nodes.master_kube` scoring
In 7.1 Base Platform, ``7.1.nodes.master_kube`` SHALL evaluate Unique kubelet versions on masters. Status matrix: Exactly one version → **PASS**. Skew → **WARNING**. Source function: ``_evaluate_master_kubelet``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.nodes.master_kube` matrix
- GIVEN collected data for ``7.1.nodes.master_kube``
- WHEN the category evaluator runs
- THEN the status follows: Exactly one version → **PASS**. Skew → **WARNING**


### Requirement: `7.1.nodes.worker_disk` scoring
In 7.1 Base Platform, ``7.1.nodes.worker_disk`` SHALL evaluate Workers vs 100 GiB (same disk signal as masters). Status matrix: Any below 100 → **INFO**. Else **PASS**. Source function: ``_evaluate_worker_disk``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.nodes.worker_disk` matrix
- GIVEN collected data for ``7.1.nodes.worker_disk``
- WHEN the category evaluator runs
- THEN the status follows: Any below 100 → **INFO**. Else **PASS**


### Requirement: `7.1.nodes.arch` scoring
In 7.1 Base Platform, ``7.1.nodes.arch`` SHALL evaluate Unique `architecture` values. Status matrix: One arch → **PASS**. Mixed → **INFO**. Source function: ``_evaluate_node_architecture``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.nodes.arch` matrix
- GIVEN collected data for ``7.1.nodes.arch``
- WHEN the category evaluator runs
- THEN the status follows: One arch → **PASS**. Mixed → **INFO**


### Requirement: `7.1.sys.firewall` scoring
In 7.1 Base Platform, ``7.1.sys.firewall`` SHALL evaluate Cluster proxy HTTP/HTTPS set. Status matrix: Proxy present → **WARNING**. No proxy → **PASS**. Proxy object missing → not this id (`7.1.sys.proxy` is N/A instead). Source function: ``_evaluate_system_firewall_proxy``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.firewall` matrix
- GIVEN collected data for ``7.1.sys.firewall``
- WHEN the category evaluator runs
- THEN the status follows: Proxy present → **WARNING**. No proxy → **PASS**. Proxy object missing → not this id (`7.1.sys.proxy` is N/A instead)


### Requirement: `7.1.sys.proxy` scoring
In 7.1 Base Platform, ``7.1.sys.proxy`` SHALL evaluate Proxy spec. Status matrix: Data missing → **NOT_APPLICABLE**. Else always **PASS** (configured or not). Source function: ``_evaluate_system_firewall_proxy``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.proxy` matrix
- GIVEN collected data for ``7.1.sys.proxy``
- WHEN the category evaluator runs
- THEN the status follows: Data missing → **NOT_APPLICABLE**. Else always **PASS** (configured or not)


### Requirement: `7.1.sys.sdn` scoring
In 7.1 Base Platform, ``7.1.sys.sdn`` SHALL evaluate Network plugin (operator relatedObjects / install-config). Status matrix: Unknown → **INFO**. Name contains `OVN` → **PASS**. Else **WARNING** (SDN deprecation text if `SDN` in name). Source function: ``_evaluate_system_network``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.sdn` matrix
- GIVEN collected data for ``7.1.sys.sdn``
- WHEN the category evaluator runs
- THEN the status follows: Unknown → **INFO**. Name contains `OVN` → **PASS**. Else **WARNING** (SDN deprecation text if `SDN` in name)


### Requirement: `7.1.sys.machine_net` scoring
In 7.1 Base Platform, ``7.1.sys.machine_net`` SHALL evaluate `machineNetwork` CIDRs in install-config. Status matrix: Found → **PASS**. Else **INFO**. Source function: ``_evaluate_system_network``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.machine_net` matrix
- GIVEN collected data for ``7.1.sys.machine_net``
- WHEN the category evaluator runs
- THEN the status follows: Found → **PASS**. Else **INFO**


### Requirement: `7.1.sys.shared_net` scoring
In 7.1 Base Platform, ``7.1.sys.shared_net`` SHALL evaluate `serviceNetwork` and `clusterNetwork` cidr in install-config. Status matrix: Both found → **PASS**. Else **INFO**. Source function: ``_evaluate_system_network``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.shared_net` matrix
- GIVEN collected data for ``7.1.sys.shared_net``
- WHEN the category evaluator runs
- THEN the status follows: Both found → **PASS**. Else **INFO**


### Requirement: `7.1.sys.dns_pods` scoring
In 7.1 Base Platform, ``7.1.sys.dns_pods`` SHALL evaluate DNS pods from `05_components`. Status matrix: Data missing → **SKIPPED**. All Running → **PASS**. Else **WARNING**. Source function: ``_evaluate_system_network``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.dns_pods` matrix
- GIVEN collected data for ``7.1.sys.dns_pods``
- WHEN the category evaluator runs
- THEN the status follows: Data missing → **SKIPPED**. All Running → **PASS**. Else **WARNING**


### Requirement: `7.1.sys.dns_config` scoring
In 7.1 Base Platform, ``7.1.sys.dns_config`` SHALL evaluate DNS operator object. Status matrix: Present → **PASS**. Missing → **SKIPPED**. Source function: ``_evaluate_system_network``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.dns_config` matrix
- GIVEN collected data for ``7.1.sys.dns_config``
- WHEN the category evaluator runs
- THEN the status follows: Present → **PASS**. Missing → **SKIPPED**


### Requirement: `7.1.sys.swap` scoring
In 7.1 Base Platform, ``7.1.sys.swap`` SHALL evaluate RHCOS default (no live swap probe). Status matrix: Always **PASS** if any nodes in list. Source function: ``_evaluate_system_node_baseline``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.swap` matrix
- GIVEN collected data for ``7.1.sys.swap``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS** if any nodes in list


### Requirement: `7.1.sys.selinux` scoring
In 7.1 Base Platform, ``7.1.sys.selinux`` SHALL evaluate Any node osImage contains `CoreOS`. Status matrix: Yes → **PASS**. Else **INFO**. Source function: ``_evaluate_system_node_baseline``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.selinux` matrix
- GIVEN collected data for ``7.1.sys.selinux``
- WHEN the category evaluator runs
- THEN the status follows: Yes → **PASS**. Else **INFO**


### Requirement: `7.1.sys.netmgr` scoring
In 7.1 Base Platform, ``7.1.sys.netmgr`` SHALL evaluate RHCOS default NetworkManager. Status matrix: Always **PASS** if any nodes. Source function: ``_evaluate_system_node_baseline``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.netmgr` matrix
- GIVEN collected data for ``7.1.sys.netmgr``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS** if any nodes


### Requirement: `7.1.sys.entropy` scoring
In 7.1 Base Platform, ``7.1.sys.entropy`` SHALL evaluate RHCOS entropy (no runtime probe). Status matrix: Always **INFO** if any nodes. Source function: ``_evaluate_system_node_baseline``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.entropy` matrix
- GIVEN collected data for ``7.1.sys.entropy``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO** if any nodes


### Requirement: `7.1.sys.ptp` scoring
In 7.1 Base Platform, ``7.1.sys.ptp`` SHALL evaluate Any node labels contain `ptp` (case-insensitive). Status matrix: Yes → **PASS**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_system_node_baseline``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.ptp` matrix
- GIVEN collected data for ``7.1.sys.ptp``
- WHEN the category evaluator runs
- THEN the status follows: Yes → **PASS**. Else **NOT_APPLICABLE**


### Requirement: `7.1.sys.hugepages` scoring
In 7.1 Base Platform, ``7.1.sys.hugepages`` SHALL evaluate Capacity `hugepages-2Mi` or `hugepages-1Gi` > 0. Status matrix: Any node → **PASS**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_system_node_resources``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.hugepages` matrix
- GIVEN collected data for ``7.1.sys.hugepages``
- WHEN the category evaluator runs
- THEN the status follows: Any node → **PASS**. Else **NOT_APPLICABLE**


### Requirement: `7.1.sys.gpu` scoring
In 7.1 Base Platform, ``7.1.sys.gpu`` SHALL evaluate Capacity keys containing `gpu` or `nvidia` with value > 0. Status matrix: Any node → **PASS**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_system_node_resources``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.gpu` matrix
- GIVEN collected data for ``7.1.sys.gpu``
- WHEN the category evaluator runs
- THEN the status follows: Any node → **PASS**. Else **NOT_APPLICABLE**


### Requirement: `7.1.sys.chrony` scoring
In 7.1 Base Platform, ``7.1.sys.chrony`` SHALL evaluate Assumption: RHCOS uses chrony. Status matrix: Always **PASS** if node list non-empty. Source function: ``_evaluate_system_time``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.chrony` matrix
- GIVEN collected data for ``7.1.sys.chrony``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS** if node list non-empty


### Requirement: `7.1.sys.ntp` scoring
In 7.1 Base Platform, ``7.1.sys.ntp`` SHALL evaluate Legacy ntpd. Status matrix: Empty node list → **NOT_APPLICABLE**. Else **NOT_APPLICABLE** (chrony message). Source function: ``_evaluate_system_time``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.ntp` matrix
- GIVEN collected data for ``7.1.sys.ntp``
- WHEN the category evaluator runs
- THEN the status follows: Empty node list → **NOT_APPLICABLE**. Else **NOT_APPLICABLE** (chrony message)


### Requirement: `7.1.sys.fips` scoring
In 7.1 Base Platform, ``7.1.sys.fips`` SHALL evaluate `fips: true` in install-config. Status matrix: Always **PASS** (wording: enabled vs not enabled). Source function: ``_evaluate_system_security``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.fips` matrix
- GIVEN collected data for ``7.1.sys.fips``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS** (wording: enabled vs not enabled)


### Requirement: `7.1.sys.auth` scoring
In 7.1 Base Platform, ``7.1.sys.auth`` SHALL evaluate OAuth identity providers. Status matrix: Data missing → **SKIPPED**. No IdPs → **WARNING**. All IdPs type `HTPasswd` → **WARNING**. Else **PASS**. Source function: ``_evaluate_system_security``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.auth` matrix
- GIVEN collected data for ``7.1.sys.auth``
- WHEN the category evaluator runs
- THEN the status follows: Data missing → **SKIPPED**. No IdPs → **WARNING**. All IdPs type `HTPasswd` → **WARNING**. Else **PASS**


### Requirement: `7.1.sys.scc` scoring
In 7.1 Base Platform, ``7.1.sys.scc`` SHALL evaluate SCC names vs built-in set. Status matrix: Data missing → **SKIPPED**. Else always **PASS**. Source function: ``_evaluate_system_security``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.scc` matrix
- GIVEN collected data for ``7.1.sys.scc``
- WHEN the category evaluator runs
- THEN the status follows: Data missing → **SKIPPED**. Else always **PASS**


### Requirement: `7.1.sys.remote_health` scoring
In 7.1 Base Platform, ``7.1.sys.remote_health`` SHALL evaluate Insights cluster operator `Available == True`. Status matrix: Yes → **PASS**. Else **WARNING**. Source function: ``_evaluate_system_remote_health``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.1.sys.remote_health` matrix
- GIVEN collected data for ``7.1.sys.remote_health``
- WHEN the category evaluator runs
- THEN the status follows: Yes → **PASS**. Else **WARNING**


### Requirement: `7.2.topo.consistent_ocp` scoring
In 7.2 Topology, ``7.2.topo.consistent_ocp`` SHALL evaluate Unique kubelet versions. Status matrix: One version → **PASS**. Else **WARNING**. Source function: ``_evaluate_topology_versions``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.topo.consistent_ocp` matrix
- GIVEN collected data for ``7.2.topo.consistent_ocp``
- WHEN the category evaluator runs
- THEN the status follows: One version → **PASS**. Else **WARNING**


### Requirement: `7.2.topo.consistent_os` scoring
In 7.2 Topology, ``7.2.topo.consistent_os`` SHALL evaluate Unique osImage. Status matrix: One image → **PASS**. Else **WARNING**. Source function: ``_evaluate_topology_versions``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.topo.consistent_os` matrix
- GIVEN collected data for ``7.2.topo.consistent_os``
- WHEN the category evaluator runs
- THEN the status follows: One image → **PASS**. Else **WARNING**


### Requirement: `7.2.topo.master_count` scoring
In 7.2 Topology, ``7.2.topo.master_count`` SHALL evaluate Count of master or control-plane role nodes. Status matrix: 3 → **PASS**. 1 → **INFO** (SNO). Else **WARNING**. Source function: ``_evaluate_topology_masters``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.topo.master_count` matrix
- GIVEN collected data for ``7.2.topo.master_count``
- WHEN the category evaluator runs
- THEN the status follows: 3 → **PASS**. 1 → **INFO** (SNO). Else **WARNING**


### Requirement: `7.2.topo.master_az` scoring
In 7.2 Topology, ``7.2.topo.master_az`` SHALL evaluate Zone labels on masters. Status matrix: ≥3 distinct zones → **PASS**. Some zones but &lt;3 → **WARNING**. No zone labels → **WARNING**. Source function: ``_evaluate_topology_masters``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.topo.master_az` matrix
- GIVEN collected data for ``7.2.topo.master_az``
- WHEN the category evaluator runs
- THEN the status follows: ≥3 distinct zones → **PASS**. Some zones but &lt;3 → **WARNING**. No zone labels → **WARNING**


### Requirement: `7.2.topo.haproxy_ha` scoring
In 7.2 Topology, ``7.2.topo.haproxy_ha`` SHALL evaluate IngressController replicas vs available. Status matrix: Data/items missing → **SKIPPED**. `replicas >= 2` and `availableReplicas >= 2` → **PASS**. Else **WARNING**. Default `spec.replicas` if unset is **2**.. Source function: ``_evaluate_topology_ingress``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.topo.haproxy_ha` matrix
- GIVEN collected data for ``7.2.topo.haproxy_ha``
- WHEN the category evaluator runs
- THEN the status follows: Data/items missing → **SKIPPED**. `replicas >= 2` and `availableReplicas >= 2` → **PASS**. Else **WARNING**. Default `spec.replicas` if unset is **2**.


### Requirement: `7.2.topo.routing_scale` scoring
In 7.2 Topology, ``7.2.topo.routing_scale`` SHALL evaluate Router replica count vs worker count. Status matrix: Same skip as HAProxy. When data present, always **PASS**. Source function: ``_evaluate_topology_ingress``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.topo.routing_scale` matrix
- GIVEN collected data for ``7.2.topo.routing_scale``
- WHEN the category evaluator runs
- THEN the status follows: Same skip as HAProxy. When data present, always **PASS**


### Requirement: `7.2.topo.sdn_nodes` scoring
In 7.2 Topology, ``7.2.topo.sdn_nodes`` SHALL evaluate Node count. Status matrix: Always **PASS**. Source function: ``_evaluate_topology_network_scale``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.topo.sdn_nodes` matrix
- GIVEN collected data for ``7.2.topo.sdn_nodes``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS**


### Requirement: `7.2.topo.sdn_pods` scoring
In 7.2 Topology, ``7.2.topo.sdn_pods`` SHALL evaluate Sum of node pod capacity. Status matrix: Always **PASS**. Source function: ``_evaluate_topology_network_scale``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.topo.sdn_pods` matrix
- GIVEN collected data for ``7.2.topo.sdn_pods``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS**


### Requirement: `7.2.node.{short}.ready` scoring
In 7.2 Topology, ``7.2.node.{short}.ready`` SHALL evaluate Ready / MemoryPressure / DiskPressure / PIDPressure. Status matrix: Ready ≠ True → **FAIL**. Else MemoryPressure True → **WARNING**. Else DiskPressure True → **WARNING**. Else PIDPressure True → **WARNING**. Else **PASS**. Source function: ``_check_node_conditions``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.node.{short}.ready` matrix
- GIVEN collected data for ``7.2.node.{short}.ready``
- WHEN the category evaluator runs
- THEN the status follows: Ready ≠ True → **FAIL**. Else MemoryPressure True → **WARNING**. Else DiskPressure True → **WARNING**. Else PIDPressure True → **WARNING**. Else **PASS**


### Requirement: `7.2.node.{short}.os` scoring
In 7.2 Topology, ``7.2.node.{short}.os`` SHALL evaluate osImage and kernel. Status matrix: Always **INFO**. Source function: ``_check_node_os``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.node.{short}.os` matrix
- GIVEN collected data for ``7.2.node.{short}.os``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO**


### Requirement: `7.2.node.{short}.cpu` scoring
In 7.2 Topology, ``7.2.node.{short}.cpu`` SHALL evaluate Capacity CPU vs 4 (control plane) or 2 (other). Status matrix: Below min → **FAIL**. Else **PASS**. Source function: ``_check_node_cpu``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.node.{short}.cpu` matrix
- GIVEN collected data for ``7.2.node.{short}.cpu``
- WHEN the category evaluator runs
- THEN the status follows: Below min → **FAIL**. Else **PASS**


### Requirement: `7.2.node.{short}.memory` scoring
In 7.2 Topology, ``7.2.node.{short}.memory`` SHALL evaluate Capacity memory vs 16.0 or 8.0 GiB. Status matrix: Below min → **FAIL**. Else **PASS**. Source function: ``_check_node_memory``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.node.{short}.memory` matrix
- GIVEN collected data for ``7.2.node.{short}.memory``
- WHEN the category evaluator runs
- THEN the status follows: Below min → **FAIL**. Else **PASS**


### Requirement: `7.2.node.{short}.disk` scoring
In 7.2 Topology, ``7.2.node.{short}.disk`` SHALL evaluate Sysinfo max disk else ephemeral-storage vs 100 GiB. Status matrix: Below 100 → **WARNING**. Else **PASS**. Source function: ``_check_node_disk``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.node.{short}.disk` matrix
- GIVEN collected data for ``7.2.node.{short}.disk``
- WHEN the category evaluator runs
- THEN the status follows: Below 100 → **WARNING**. Else **PASS**


### Requirement: `7.2.node.{short}.kubelet` scoring
In 7.2 Topology, ``7.2.node.{short}.kubelet`` SHALL evaluate kubelet and CRI versions. Status matrix: Always **INFO**. Source function: ``_check_node_kubelet``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.node.{short}.kubelet` matrix
- GIVEN collected data for ``7.2.node.{short}.kubelet``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO**


### Requirement: `7.2.node.{short}.sysreserved` scoring
In 7.2 Topology, ``7.2.node.{short}.sysreserved`` SHALL evaluate systemReserved on nodes with **≥ 64.0 GiB** RAM. Status matrix: **No check** if RAM &lt; 64 GiB, or node status config already has `systemReserved`, or a matching/global KubeletConfig already sets it. Else **WARNING**.. Source function: ``_check_system_reserved``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.node.{short}.sysreserved` matrix
- GIVEN collected data for ``7.2.node.{short}.sysreserved``
- WHEN the category evaluator runs
- THEN the status follows: **No check** if RAM &lt; 64 GiB, or node status config already has `systemReserved`, or a matching/global KubeletConfig already sets it. Else **WARNING**.


### Requirement: `7.2.mcp.{name}` scoring
In 7.2 Topology, ``7.2.mcp.{name}`` SHALL evaluate Degraded / Updating / paused / updated counts. Status matrix: `Degraded` True or `degradedMachineCount > 0` → **FAIL**. Updating → **WARNING**. `spec.paused == true` and counts all current → **WARNING**. Not `Updated` with `total > 0` → **WARNING**. Else **PASS**. Source function: ``_evaluate_mcp``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.mcp.{name}` matrix
- GIVEN collected data for ``7.2.mcp.{name}``
- WHEN the category evaluator runs
- THEN the status follows: `Degraded` True or `degradedMachineCount > 0` → **FAIL**. Updating → **WARNING**. `spec.paused == true` and counts all current → **WARNING**. Not `Updated` with `total > 0` → **WARNING**. Else **PASS**


### Requirement: `7.2.etcd.members` scoring
In 7.2 Topology, ``7.2.etcd.members`` SHALL evaluate `EtcdMembersDegraded` / `EtcdMembersAvailable`. Status matrix: Degraded True → **FAIL**. Available False → **WARNING**. Else **PASS**. Source function: ``_evaluate_etcd``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.etcd.members` matrix
- GIVEN collected data for ``7.2.etcd.members``
- WHEN the category evaluator runs
- THEN the status follows: Degraded True → **FAIL**. Available False → **WARNING**. Else **PASS**


### Requirement: `7.2.etcd.quorum` scoring
In 7.2 Topology, ``7.2.etcd.quorum`` SHALL evaluate `EtcdMembersProgressing` True. Status matrix: True → **WARNING**. Else **PASS**. Source function: ``_evaluate_etcd``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.etcd.quorum` matrix
- GIVEN collected data for ``7.2.etcd.quorum``
- WHEN the category evaluator runs
- THEN the status follows: True → **WARNING**. Else **PASS**


### Requirement: `7.2.etcd.pods` scoring
In 7.2 Topology, ``7.2.etcd.pods`` SHALL evaluate No etcd member pods. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_etcd_pods``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.etcd.pods` matrix
- GIVEN collected data for ``7.2.etcd.pods``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.2.etcd.pod_health` scoring
In 7.2 Topology, ``7.2.etcd.pod_health`` SHALL evaluate Member pod phase. Status matrix: Any not Running → **FAIL**. Else **PASS**. Source function: ``_check_etcd_pod_health``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.etcd.pod_health` matrix
- GIVEN collected data for ``7.2.etcd.pod_health``
- WHEN the category evaluator runs
- THEN the status follows: Any not Running → **FAIL**. Else **PASS**


### Requirement: `7.2.etcd.guards` scoring
In 7.2 Topology, ``7.2.etcd.guards`` SHALL evaluate Guard pods (omitted if none). Status matrix: All Running → **PASS**. Else **WARNING**. Source function: ``_check_etcd_guard_pods``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.2.etcd.guards` matrix
- GIVEN collected data for ``7.2.etcd.guards``
- WHEN the category evaluator runs
- THEN the status follows: All Running → **PASS**. Else **WARNING**


### Requirement: `7.3.co` scoring
In 7.3 Component Checks, ``7.3.co`` SHALL evaluate Cluster operators object missing. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_cluster_operators``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.co` matrix
- GIVEN collected data for ``7.3.co``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.3.co.{name}` scoring
In 7.3 Component Checks, ``7.3.co.{name}`` SHALL evaluate Per cluster operator Available / Degraded / Progressing. Status matrix: Degraded True → **FAIL**. Available ≠ True → **WARNING**. Progressing True → **WARNING**. Else **PASS**. Source function: ``_evaluate_cluster_operators``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.co.{name}` matrix
- GIVEN collected data for ``7.3.co.{name}``
- WHEN the category evaluator runs
- THEN the status follows: Degraded True → **FAIL**. Available ≠ True → **WARNING**. Progressing True → **WARNING**. Else **PASS**


### Requirement: `7.3.network` scoring
In 7.3 Component Checks, ``7.3.network`` SHALL evaluate Network CR missing. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_network``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.network` matrix
- GIVEN collected data for ``7.3.network``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.3.network.plugin` scoring
In 7.3 Component Checks, ``7.3.network.plugin`` SHALL evaluate `networkType`. Status matrix: `OVNKubernetes` → **PASS**. `OpenShiftSDN` → **WARNING**. Other → **PASS**. Source function: ``_evaluate_network``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.network.plugin` matrix
- GIVEN collected data for ``7.3.network.plugin``
- WHEN the category evaluator runs
- THEN the status follows: `OVNKubernetes` → **PASS**. `OpenShiftSDN` → **WARNING**. Other → **PASS**


### Requirement: `7.3.network.cluster_cidr` scoring
In 7.3 Component Checks, ``7.3.network.cluster_cidr`` SHALL evaluate Cluster CIDRs present. Status matrix: Emitted only if list non-empty; always **INFO**. Source function: ``_evaluate_network``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.network.cluster_cidr` matrix
- GIVEN collected data for ``7.3.network.cluster_cidr``
- WHEN the category evaluator runs
- THEN the status follows: Emitted only if list non-empty; always **INFO**


### Requirement: `7.3.network.service_cidr` scoring
In 7.3 Component Checks, ``7.3.network.service_cidr`` SHALL evaluate Service CIDRs present. Status matrix: Emitted only if list non-empty; always **INFO**. Source function: ``_evaluate_network``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.network.service_cidr` matrix
- GIVEN collected data for ``7.3.network.service_cidr``
- WHEN the category evaluator runs
- THEN the status follows: Emitted only if list non-empty; always **INFO**


### Requirement: `7.3.ingress` scoring
In 7.3 Component Checks, ``7.3.ingress`` SHALL evaluate IngressController missing. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_ingress``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.ingress` matrix
- GIVEN collected data for ``7.3.ingress``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.3.ingress.{name}` scoring
In 7.3 Component Checks, ``7.3.ingress.{name}`` SHALL evaluate Per controller Available vs replicas. Status matrix: Available ≠ True → **FAIL**. `availableReplicas < desired` → **WARNING**. Else **PASS**. Desired defaults from spec or status or **1**. Source function: ``_evaluate_ingress``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.ingress.{name}` matrix
- GIVEN collected data for ``7.3.ingress.{name}``
- WHEN the category evaluator runs
- THEN the status follows: Available ≠ True → **FAIL**. `availableReplicas < desired` → **WARNING**. Else **PASS**. Desired defaults from spec or status or **1**


### Requirement: `7.3.registry.state` scoring
In 7.3 Component Checks, ``7.3.registry.state`` SHALL evaluate Image registry. Status matrix: Missing → N/A. `managementState == Removed` → **WARNING**. Available True → **PASS**. Else **WARNING**. Source function: ``_evaluate_image_registry``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.registry.state` matrix
- GIVEN collected data for ``7.3.registry.state``
- WHEN the category evaluator runs
- THEN the status follows: Missing → N/A. `managementState == Removed` → **WARNING**. Available True → **PASS**. Else **WARNING**


### Requirement: `7.3.dns.operator` scoring
In 7.3 Component Checks, ``7.3.dns.operator`` SHALL evaluate DNS operator conditions. Status matrix: Missing → N/A. Degraded True → **FAIL**. Available True → **PASS**. Else **WARNING**. Source function: ``_evaluate_dns``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.dns.operator` matrix
- GIVEN collected data for ``7.3.dns.operator``
- WHEN the category evaluator runs
- THEN the status follows: Missing → N/A. Degraded True → **FAIL**. Available True → **PASS**. Else **WARNING**


### Requirement: `7.3.dns.config` scoring
In 7.3 Component Checks, ``7.3.dns.config`` SHALL evaluate Cluster domain string. Status matrix: Emitted only if config present and domain non-empty; always **INFO**. Source function: ``_evaluate_dns``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.dns.config` matrix
- GIVEN collected data for ``7.3.dns.config``
- WHEN the category evaluator runs
- THEN the status follows: Emitted only if config present and domain non-empty; always **INFO**


### Requirement: `7.3.webhooks.validatingwebhooks` / `.mutatingwebhooks` scoring
In 7.3 Component Checks, ``7.3.webhooks.validatingwebhooks` / `.mutatingwebhooks`` SHALL evaluate Timeout and failurePolicy. Status matrix: Data missing → N/A. Fail policy **and** namespaceSelector values start with `openshift-` / `kube-system` / `kube-public` / `default` → **FAIL**. Else timeout > **10** or `failurePolicy == Fail` → **WARNING**. Else **PASS**. Default timeout **10**, default failurePolicy **Ignore**. Source function: ``_evaluate_webhooks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.webhooks.validatingwebhooks` / `.mutatingwebhooks` matrix
- GIVEN collected data for ``7.3.webhooks.validatingwebhooks` / `.mutatingwebhooks``
- WHEN the category evaluator runs
- THEN the status follows: Data missing → N/A. Fail policy **and** namespaceSelector values start with `openshift-` / `kube-system` / `kube-public` / `default` → **FAIL**. Else timeout > **10** or `failurePolicy == Fail` → **WARNING**. Else **PASS**. Default timeout **10**, default failurePolicy **Ignore**


### Requirement: `7.3.monitoring.config` scoring
In 7.3 Component Checks, ``7.3.monitoring.config`` SHALL evaluate `cluster-monitoring-config`. Status matrix: Missing CM → **FAIL**. `config.yaml` contains `volumeClaimTemplate` or `storage` → **PASS**. Else **FAIL**. Source function: ``_evaluate_monitoring_config``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.monitoring.config` matrix
- GIVEN collected data for ``7.3.monitoring.config``
- WHEN the category evaluator runs
- THEN the status follows: Missing CM → **FAIL**. `config.yaml` contains `volumeClaimTemplate` or `storage` → **PASS**. Else **FAIL**


### Requirement: `7.3.version` scoring
In 7.3 Component Checks, ``7.3.version`` SHALL evaluate ClusterVersion history[0].state. Status matrix: Missing CV → N/A. `Completed` → **PASS**. Else **WARNING**. Source function: ``_evaluate_cluster_version``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.version` matrix
- GIVEN collected data for ``7.3.version``
- WHEN the category evaluator runs
- THEN the status follows: Missing CV → N/A. `Completed` → **PASS**. Else **WARNING**


### Requirement: `7.3.etcd.endpoints` scoring
In 7.3 Component Checks, ``7.3.etcd.endpoints`` SHALL evaluate Lines with `etcd-`, `Running`, not `guard`. Status matrix: ≥3 → **PASS**. >0 and <3 → **WARNING**. Output but 0 members → **SKIPPED**. Empty output → N/A. Source function: ``_evaluate_etcd_endpoints``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.etcd.endpoints` matrix
- GIVEN collected data for ``7.3.etcd.endpoints``
- WHEN the category evaluator runs
- THEN the status follows: ≥3 → **PASS**. >0 and <3 → **WARNING**. Output but 0 members → **SKIPPED**. Empty output → N/A


### Requirement: `7.3.etcd.leader` scoring
In 7.3 Component Checks, ``7.3.etcd.leader`` SHALL evaluate `04_topology` etcd_status output contains `leader`. Status matrix: Yes → **PASS**. Else **SKIPPED**. Source function: ``_evaluate_etcd_leader``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.etcd.leader` matrix
- GIVEN collected data for ``7.3.etcd.leader``
- WHEN the category evaluator runs
- THEN the status follows: Yes → **PASS**. Else **SKIPPED**


### Requirement: `7.3.etcd.health` scoring
In 7.3 Component Checks, ``7.3.etcd.health`` SHALL evaluate Same output; exit_code. Status matrix: exit ≠ 0 or empty → **SKIPPED**. etcd- line without Running → **FAIL**. Else **PASS**. Source function: ``_evaluate_etcd_health``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.etcd.health` matrix
- GIVEN collected data for ``7.3.etcd.health``
- WHEN the category evaluator runs
- THEN the status follows: exit ≠ 0 or empty → **SKIPPED**. etcd- line without Running → **FAIL**. Else **PASS**


### Requirement: `7.3.etcd.3_5_4` … `7.3.etcd.3_5_9` (ids with dots→underscores: `3_5_4` through `3_5_9`, plus `3_5_8_1`/`_2`/`_3`) scoring
In 7.3 Component Checks, ``7.3.etcd.3_5_4` … `7.3.etcd.3_5_9` (ids with dots→underscores: `3_5_4` through `3_5_9`, plus `3_5_8_1`/`_2`/`_3`)` SHALL evaluate Prometheus placeholders. Status matrix: Always **SKIPPED**. Source function: ``_evaluate_etcd_metrics_placeholders``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.etcd.3_5_4` … `7.3.etcd.3_5_9` (ids with dots→underscores: `3_5_4` through `3_5_9`, plus `3_5_8_1`/`_2`/`_3`) matrix
- GIVEN collected data for ``7.3.etcd.3_5_4` … `7.3.etcd.3_5_9` (ids with dots→underscores: `3_5_4` through `3_5_9`, plus `3_5_8_1`/`_2`/`_3`)`
- WHEN the category evaluator runs
- THEN the status follows: Always **SKIPPED**


### Requirement: `7.3.ingress.agg` scoring
In 7.3 Component Checks, ``7.3.ingress.agg`` SHALL evaluate Ingress missing. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_ingress_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.ingress.agg` matrix
- GIVEN collected data for ``7.3.ingress.agg``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.3.haproxy.status` scoring
In 7.3 Component Checks, ``7.3.haproxy.status`` SHALL evaluate Available True count vs items. Status matrix: All Available → **PASS**. Else **WARNING**. Source function: ``_evaluate_ingress_status``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.haproxy.status` matrix
- GIVEN collected data for ``7.3.haproxy.status``
- WHEN the category evaluator runs
- THEN the status follows: All Available → **PASS**. Else **WARNING**


### Requirement: `7.3.ingress.tuning` scoring
In 7.3 Component Checks, ``7.3.ingress.tuning`` SHALL evaluate `tuningOptions` non-empty/non-`0s`. Status matrix: Always **INFO**. Source function: ``_evaluate_ingress_tuning``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.ingress.tuning` matrix
- GIVEN collected data for ``7.3.ingress.tuning``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO**


### Requirement: `7.3.ingress.sharding` scoring
In 7.3 Component Checks, ``7.3.ingress.sharding`` SHALL evaluate Multiple controllers vs selectors. Status matrix: >1 controller and none sharded → **WARNING**. >1 and some selectors → **PASS**. Single controller → **INFO**. Source function: ``_evaluate_ingress_sharding``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.ingress.sharding` matrix
- GIVEN collected data for ``7.3.ingress.sharding``
- WHEN the category evaluator runs
- THEN the status follows: >1 controller and none sharded → **WARNING**. >1 and some selectors → **PASS**. Single controller → **INFO**


### Requirement: `7.3.storage.csi` scoring
In 7.3 Component Checks, ``7.3.storage.csi`` SHALL evaluate Provisioner names. Status matrix: Any CSI-like → **PASS**. Else **WARNING**. SC missing → N/A. Source function: ``_evaluate_storage_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.storage.csi` matrix
- GIVEN collected data for ``7.3.storage.csi``
- WHEN the category evaluator runs
- THEN the status follows: Any CSI-like → **PASS**. Else **WARNING**. SC missing → N/A


### Requirement: `7.3.storage.flexvolumes` scoring
In 7.3 Component Checks, ``7.3.storage.flexvolumes`` SHALL evaluate `flex` in provisioner. Status matrix: Present → **WARNING**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_storage_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.storage.flexvolumes` matrix
- GIVEN collected data for ``7.3.storage.flexvolumes``
- WHEN the category evaluator runs
- THEN the status follows: Present → **WARNING**. Else **NOT_APPLICABLE**


### Requirement: `7.3.storage.default_sc` scoring
In 7.3 Component Checks, ``7.3.storage.default_sc`` SHALL evaluate Annotation `storageclass.kubernetes.io/is-default-class=true`. Status matrix: None → **WARNING**. Else **PASS**. Source function: ``_evaluate_storage_classes``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.storage.default_sc` matrix
- GIVEN collected data for ``7.3.storage.default_sc``
- WHEN the category evaluator runs
- THEN the status follows: None → **WARNING**. Else **PASS**


### Requirement: `7.3.storage.pvs` scoring
In 7.3 Component Checks, ``7.3.storage.pvs`` SHALL evaluate PV phase Failed+Pending. Status matrix: Any → **WARNING**. Else **PASS**. Source function: ``_evaluate_pvs``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.storage.pvs` matrix
- GIVEN collected data for ``7.3.storage.pvs``
- WHEN the category evaluator runs
- THEN the status follows: Any → **WARNING**. Else **PASS**


### Requirement: `7.3.storage.pvcs` scoring
In 7.3 Component Checks, ``7.3.storage.pvcs`` SHALL evaluate PVC phase ≠ Bound. Status matrix: Any → **WARNING**. Else **PASS**. Source function: ``_evaluate_pvcs``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.storage.pvcs` matrix
- GIVEN collected data for ``7.3.storage.pvcs``
- WHEN the category evaluator runs
- THEN the status follows: Any → **WARNING**. Else **PASS**


### Requirement: `7.3.crds` scoring
In 7.3 Component Checks, ``7.3.crds`` SHALL evaluate CRD count. Status matrix: **> 500** → **WARNING**. Else **INFO**. Source function: ``_evaluate_crds``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.crds` matrix
- GIVEN collected data for ``7.3.crds``
- WHEN the category evaluator runs
- THEN the status follows: **> 500** → **WARNING**. Else **INFO**


### Requirement: `7.3.deprecated_apis` scoring
In 7.3 Component Checks, ``7.3.deprecated_apis`` SHALL evaluate APIRequestCount `removedInRelease` and request count > 0. Status matrix: Any → **WARNING**. Else **PASS**. Source function: ``_evaluate_deprecated_apis``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.deprecated_apis` matrix
- GIVEN collected data for ``7.3.deprecated_apis``
- WHEN the category evaluator runs
- THEN the status follows: Any → **WARNING**. Else **PASS**


### Requirement: `7.3.net.kubeproxy` scoring
In 7.3 Component Checks, ``7.3.net.kubeproxy`` SHALL evaluate Network type. Status matrix: Empty type → N/A. OVNKubernetes → **NOT_APPLICABLE**. Else **INFO**. Source function: ``_evaluate_net_plugin_type``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.net.kubeproxy` matrix
- GIVEN collected data for ``7.3.net.kubeproxy``
- WHEN the category evaluator runs
- THEN the status follows: Empty type → N/A. OVNKubernetes → **NOT_APPLICABLE**. Else **INFO**


### Requirement: `7.3.net.ovnkube` scoring
In 7.3 Component Checks, ``7.3.net.ovnkube`` SHALL evaluate Network type. Status matrix: OVNKubernetes → **PASS**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_net_plugin_type``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.net.ovnkube` matrix
- GIVEN collected data for ``7.3.net.ovnkube``
- WHEN the category evaluator runs
- THEN the status follows: OVNKubernetes → **PASS**. Else **NOT_APPLICABLE**


### Requirement: `7.3.net.featuregates` scoring
In 7.3 Component Checks, ``7.3.net.featuregates`` SHALL evaluate Cluster operators present. Status matrix: Missing → **SKIPPED**. Else always **PASS** (does not actually detect TechPreview). Source function: ``_evaluate_net_config``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.net.featuregates` matrix
- GIVEN collected data for ``7.3.net.featuregates``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Else always **PASS** (does not actually detect TechPreview)


### Requirement: `7.3.net.kubelet_config` scoring
In 7.3 Component Checks, ``7.3.net.kubelet_config`` SHALL evaluate MachineConfig names containing `kubelet`. Status matrix: MCP missing → N/A. Else always **PASS**. Source function: ``_evaluate_net_config``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.net.kubelet_config` matrix
- GIVEN collected data for ``7.3.net.kubelet_config``
- WHEN the category evaluator runs
- THEN the status follows: MCP missing → N/A. Else always **PASS**


### Requirement: `7.3.net.ipstack` scoring
In 7.3 Component Checks, ``7.3.net.ipstack`` SHALL evaluate OVN ipv4/ipv6 or CIDR characters. Status matrix: Always **PASS** when data exists; N/A if both missing. Source function: ``_evaluate_net_ip_stack``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.net.ipstack` matrix
- GIVEN collected data for ``7.3.net.ipstack``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS** when data exists; N/A if both missing


### Requirement: `7.3.net.ipsec` scoring
In 7.3 Component Checks, ``7.3.net.ipsec`` SHALL evaluate `ipsecConfig.mode` (default Disabled). Status matrix: Missing operator → N/A. Else **INFO**. Source function: ``_evaluate_net_ipsec``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.net.ipsec` matrix
- GIVEN collected data for ``7.3.net.ipsec``
- WHEN the category evaluator runs
- THEN the status follows: Missing operator → N/A. Else **INFO**


### Requirement: `7.3.net.multinet` scoring
In 7.3 Component Checks, ``7.3.net.multinet`` SHALL evaluate NetworkAttachmentDefinitions. Status matrix: Always **INFO** (including “not collected”). Source function: ``_evaluate_net_additional``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.net.multinet` matrix
- GIVEN collected data for ``7.3.net.multinet``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO** (including “not collected”)


### Requirement: `7.3.net.hwnet` scoring
In 7.3 Component Checks, ``7.3.net.hwnet`` SHALL evaluate NNCP items. Status matrix: Items → **INFO**. None or not collected → **NOT_APPLICABLE**. Source function: ``_evaluate_net_additional``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.net.hwnet` matrix
- GIVEN collected data for ``7.3.net.hwnet``
- WHEN the category evaluator runs
- THEN the status follows: Items → **INFO**. None or not collected → **NOT_APPLICABLE**


### Requirement: `7.3.misc.master_config` scoring
In 7.3 Component Checks, ``7.3.misc.master_config`` SHALL evaluate Scheduler profile / mastersSchedulable. Status matrix: Missing → **SKIPPED**. Else always **PASS**. Source function: ``_evaluate_misc_master_and_limits``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.master_config` matrix
- GIVEN collected data for ``7.3.misc.master_config``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Else always **PASS**


### Requirement: `7.3.misc.ocp_limits` scoring
In 7.3 Component Checks, ``7.3.misc.ocp_limits`` SHALL evaluate Subscription limits. Status matrix: Always **SKIPPED**. Source function: ``_evaluate_misc_master_and_limits``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.ocp_limits` matrix
- GIVEN collected data for ``7.3.misc.ocp_limits``
- WHEN the category evaluator runs
- THEN the status follows: Always **SKIPPED**


### Requirement: `7.3.misc.lb` scoring
In 7.3 Component Checks, ``7.3.misc.lb`` SHALL evaluate Infrastructure platform. Status matrix: Missing → N/A. Else **INFO**. Source function: ``_evaluate_misc_loadbalancer``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.lb` matrix
- GIVEN collected data for ``7.3.misc.lb``
- WHEN the category evaluator runs
- THEN the status follows: Missing → N/A. Else **INFO**


### Requirement: `7.3.misc.metallb_installed` scoring
In 7.3 Component Checks, ``7.3.misc.metallb_installed`` SHALL evaluate Cluster operator name contains `metallb`. Status matrix: Installed → **PASS**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_misc_loadbalancer``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.metallb_installed` matrix
- GIVEN collected data for ``7.3.misc.metallb_installed``
- WHEN the category evaluator runs
- THEN the status follows: Installed → **PASS**. Else **NOT_APPLICABLE**


### Requirement: `7.3.misc.metallb_config` / `.metallb_l2` scoring
In 7.3 Component Checks, ``7.3.misc.metallb_config` / `.metallb_l2`` SHALL evaluate MetalLB details. Status matrix: Installed → **SKIPPED**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_misc_loadbalancer``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.metallb_config` / `.metallb_l2` matrix
- GIVEN collected data for ``7.3.misc.metallb_config` / `.metallb_l2``
- WHEN the category evaluator runs
- THEN the status follows: Installed → **SKIPPED**. Else **NOT_APPLICABLE**


### Requirement: `7.3.misc.mcp` scoring
In 7.3 Component Checks, ``7.3.misc.mcp`` SHALL evaluate `check_mcp_degraded` on MachineConfigs. Status matrix: Missing → N/A. Degraded or updating → **WARNING**. Else **PASS**. Source function: ``_evaluate_misc_mcp_and_sctp``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.mcp` matrix
- GIVEN collected data for ``7.3.misc.mcp``
- WHEN the category evaluator runs
- THEN the status follows: Missing → N/A. Degraded or updating → **WARNING**. Else **PASS**


### Requirement: `7.3.misc.sctp` scoring
In 7.3 Component Checks, ``7.3.misc.sctp`` SHALL evaluate SCTP. Status matrix: Always **NOT_APPLICABLE**. Source function: ``_evaluate_misc_mcp_and_sctp``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.sctp` matrix
- GIVEN collected data for ``7.3.misc.sctp``
- WHEN the category evaluator runs
- THEN the status follows: Always **NOT_APPLICABLE**


### Requirement: `7.3.misc.capabilities` scoring
In 7.3 Component Checks, ``7.3.misc.capabilities`` SHALL evaluate ClusterVersion capabilities. Status matrix: Missing CV → N/A. Else always **PASS**. Source function: ``_evaluate_misc_capabilities_and_workloads``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.capabilities` matrix
- GIVEN collected data for ``7.3.misc.capabilities``
- WHEN the category evaluator runs
- THEN the status follows: Missing CV → N/A. Else always **PASS**


### Requirement: `7.3.misc.sandboxed` scoring
In 7.3 Component Checks, ``7.3.misc.sandboxed`` SHALL evaluate Kata. Status matrix: Always **NOT_APPLICABLE**. Source function: ``_evaluate_misc_capabilities_and_workloads``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.sandboxed` matrix
- GIVEN collected data for ``7.3.misc.sandboxed``
- WHEN the category evaluator runs
- THEN the status follows: Always **NOT_APPLICABLE**


### Requirement: `7.3.misc.cgroups` scoring
In 7.3 Component Checks, ``7.3.misc.cgroups`` SHALL evaluate Heuristic crun / RHEL 9 / CoreOS → v2. Status matrix: All v2 → **PASS**. Else **INFO**. Source function: ``_evaluate_misc_capabilities_and_workloads``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.cgroups` matrix
- GIVEN collected data for ``7.3.misc.cgroups``
- WHEN the category evaluator runs
- THEN the status follows: All v2 → **PASS**. Else **INFO**


### Requirement: `7.3.misc.deploymentconfig` scoring
In 7.3 Component Checks, ``7.3.misc.deploymentconfig`` SHALL evaluate DC query. Status matrix: Always **SKIPPED**. Source function: ``_evaluate_misc_capabilities_and_workloads``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.deploymentconfig` matrix
- GIVEN collected data for ``7.3.misc.deploymentconfig``
- WHEN the category evaluator runs
- THEN the status follows: Always **SKIPPED**


### Requirement: `7.3.misc.wp_enabled` scoring
In 7.3 Component Checks, ``7.3.misc.wp_enabled`` SHALL evaluate MachineConfig name contains `performance`. Status matrix: Detected → **PASS**. Else **INFO**. Source function: ``_evaluate_misc_capabilities_and_workloads``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.wp_enabled` matrix
- GIVEN collected data for ``7.3.misc.wp_enabled``
- WHEN the category evaluator runs
- THEN the status follows: Detected → **PASS**. Else **INFO**


### Requirement: `7.3.misc.pp_mcp` / `.pp_status` / `.pp_config` scoring
In 7.3 Component Checks, ``7.3.misc.pp_mcp` / `.pp_status` / `.pp_config`` SHALL evaluate Performance profile details. Status matrix: Not detected → **NOT_APPLICABLE**. Detected → **SKIPPED**. Source function: ``_evaluate_misc_capabilities_and_workloads``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.3.misc.pp_mcp` / `.pp_status` / `.pp_config` matrix
- GIVEN collected data for ``7.3.misc.pp_mcp` / `.pp_status` / `.pp_config``
- WHEN the category evaluator runs
- THEN the status follows: Not detected → **NOT_APPLICABLE**. Detected → **SKIPPED**


### Requirement: `7.4.{product}` scoring
In 7.4 Layered Products, ``7.4.{product}`` SHALL evaluate Presence of listed CRs (CNV, ACM, ACS, logging, pipelines, mesh, MTV, OADP, serverless serving/eventing, Quay, Data Science). Status matrix: See above. Source function: ``_evaluate_layered_product``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.4.{product}` matrix
- GIVEN collected data for ``7.4.{product}``
- WHEN the category evaluator runs
- THEN the status follows: See above


### Requirement: `7.4.cnv.state` scoring
In 7.4 Layered Products, ``7.4.cnv.state`` SHALL evaluate HyperConverged. Status matrix: Not installed → N/A. Degraded True → **FAIL**. Available True → **PASS**. Else **WARNING**. Source function: ``_evaluate_cnv_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.4.cnv.state` matrix
- GIVEN collected data for ``7.4.cnv.state``
- WHEN the category evaluator runs
- THEN the status follows: Not installed → N/A. Degraded True → **FAIL**. Available True → **PASS**. Else **WARNING**


### Requirement: `7.4.cnv.kubevirt` scoring
In 7.4 Layered Products, ``7.4.cnv.kubevirt`` SHALL evaluate KubeVirt phase. Status matrix: Missing → **SKIPPED**. `Deployed` → **PASS**. Else **WARNING**. Source function: ``_evaluate_cnv_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.4.cnv.kubevirt` matrix
- GIVEN collected data for ``7.4.cnv.kubevirt``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. `Deployed` → **PASS**. Else **WARNING**


### Requirement: `7.4.cnv.pods` scoring
In 7.4 Layered Products, ``7.4.cnv.pods`` SHALL evaluate CNV pod phase not Running/Succeeded. Status matrix: Any → **WARNING**. Else **PASS**. Omitted if pod data missing. Source function: ``_evaluate_cnv_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.4.cnv.pods` matrix
- GIVEN collected data for ``7.4.cnv.pods``
- WHEN the category evaluator runs
- THEN the status follows: Any → **WARNING**. Else **PASS**. Omitted if pod data missing


### Requirement: `7.4.cnv.live_migratable` scoring
In 7.4 Layered Products, ``7.4.cnv.live_migratable`` SHALL evaluate VMI LiveMigratable False; VM evictionStrategy. Status matrix: VMI missing → **SKIPPED**. Any False → **WARNING**. Else eviction lines → **INFO**. Else **PASS**. Source function: ``_evaluate_cnv_live_migratable``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.4.cnv.live_migratable` matrix
- GIVEN collected data for ``7.4.cnv.live_migratable``
- WHEN the category evaluator runs
- THEN the status follows: VMI missing → **SKIPPED**. Any False → **WARNING**. Else eviction lines → **INFO**. Else **PASS**


### Requirement: `7.4.acm.agent` scoring
In 7.4 Layered Products, ``7.4.acm.agent`` SHALL evaluate klusterlet pods when hub missing. Status matrix: Found → **PASS** (then return). Source function: ``_evaluate_acm_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.4.acm.agent` matrix
- GIVEN collected data for ``7.4.acm.agent``
- WHEN the category evaluator runs
- THEN the status follows: Found → **PASS** (then return)


### Requirement: `7.4.acm.state` scoring
In 7.4 Layered Products, ``7.4.acm.state`` SHALL evaluate MultiClusterHub. Status matrix: Not installed → N/A. Phase Running or Available → **PASS**. Else **WARNING**. Source function: ``_evaluate_acm_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.4.acm.state` matrix
- GIVEN collected data for ``7.4.acm.state``
- WHEN the category evaluator runs
- THEN the status follows: Not installed → N/A. Phase Running or Available → **PASS**. Else **WARNING**


### Requirement: `7.4.logging.state` scoring
In 7.4 Layered Products, ``7.4.logging.state`` SHALL evaluate ClusterLogging Ready. Status matrix: Not installed → N/A. Ready True → **PASS**. Else **WARNING**. Source function: ``_evaluate_logging_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.4.logging.state` matrix
- GIVEN collected data for ``7.4.logging.state``
- WHEN the category evaluator runs
- THEN the status follows: Not installed → N/A. Ready True → **PASS**. Else **WARNING**


### Requirement: `7.4.logging.loki` scoring
In 7.4 Layered Products, ``7.4.logging.loki`` SHALL evaluate LokiStack not `_hc_not_found`. Status matrix: **INFO** if present. Source function: ``_evaluate_logging_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.4.logging.loki` matrix
- GIVEN collected data for ``7.4.logging.loki``
- WHEN the category evaluator runs
- THEN the status follows: **INFO** if present


### Requirement: `7.5.kubelet_health` scoring
In 7.5 Cluster Health, ``7.5.kubelet_health`` SHALL evaluate Node Ready. Status matrix: Missing → **SKIPPED**. Any not Ready → **WARNING**. Else **PASS**. Source function: ``_evaluate_health_kubelet``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.kubelet_health` matrix
- GIVEN collected data for ``7.5.kubelet_health``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Any not Ready → **WARNING**. Else **PASS**


### Requirement: `7.5.mcp_health` scoring
In 7.5 Cluster Health, ``7.5.mcp_health`` SHALL evaluate Degraded MCP names. Status matrix: Missing → **SKIPPED**. Any degraded → **FAIL**. Else **PASS**. Source function: ``_evaluate_health_machine_config``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.mcp_health` matrix
- GIVEN collected data for ``7.5.mcp_health``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Any degraded → **FAIL**. Else **PASS**


### Requirement: `7.5.operator_state` scoring
In 7.5 Cluster Health, ``7.5.operator_state`` SHALL evaluate Degraded cluster operators. Status matrix: Missing → **SKIPPED**. Any → **FAIL**. Else **PASS**. Source function: ``_evaluate_health_operator_state``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.operator_state` matrix
- GIVEN collected data for ``7.5.operator_state``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Any → **FAIL**. Else **PASS**


### Requirement: `7.5.registry_health` scoring
In 7.5 Cluster Health, ``7.5.registry_health`` SHALL evaluate `managementState`. Status matrix: Missing → **SKIPPED**. Managed → **PASS**. Unmanaged/Removed → **INFO**. Else **WARNING**. Source function: ``_evaluate_health_registry``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.registry_health` matrix
- GIVEN collected data for ``7.5.registry_health``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Managed → **PASS**. Unmanaged/Removed → **INFO**. Else **WARNING**


### Requirement: `7.5.pod_restarts` scoring
In 7.5 Cluster Health, ``7.5.pod_restarts`` SHALL evaluate Any container `restartCount > 10`. Status matrix: Missing pods → **SKIPPED**. Any → **WARNING**. Else **PASS**. Source function: ``_evaluate_health_pod_restarts``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.pod_restarts` matrix
- GIVEN collected data for ``7.5.pod_restarts``
- WHEN the category evaluator runs
- THEN the status follows: Missing pods → **SKIPPED**. Any → **WARNING**. Else **PASS**


### Requirement: `7.5.node_roles` scoring
In 7.5 Cluster Health, ``7.5.node_roles`` SHALL evaluate Nodes with no role labels. Status matrix: Missing → **SKIPPED**. Any unlabeled → **FAIL**. Else **PASS**. Source function: ``_evaluate_health_node_roles``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.node_roles` matrix
- GIVEN collected data for ``7.5.node_roles``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Any unlabeled → **FAIL**. Else **PASS**


### Requirement: `7.5.machineset` / `.pdb` / `.vol_mount` scoring
In 7.5 Cluster Health, ``7.5.machineset` / `.pdb` / `.vol_mount`` SHALL evaluate Not in standard collect. Status matrix: Always **SKIPPED**. Source function: ``_evaluate_health_static_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.machineset` / `.pdb` / `.vol_mount` matrix
- GIVEN collected data for ``7.5.machineset` / `.pdb` / `.vol_mount``
- WHEN the category evaluator runs
- THEN the status follows: Always **SKIPPED**


### Requirement: `7.5.alerts.cp` / `.node` / `.overcommit` scoring
In 7.5 Cluster Health, ``7.5.alerts.cp` / `.node` / `.overcommit`` SHALL evaluate Alertname keyword buckets. Status matrix: Alerts missing → **SKIPPED**. Any match → **WARNING**. Else **PASS**. Source function: ``_evaluate_health_alert_breakdown``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.alerts.cp` / `.node` / `.overcommit` matrix
- GIVEN collected data for ``7.5.alerts.cp` / `.node` / `.overcommit``
- WHEN the category evaluator runs
- THEN the status follows: Alerts missing → **SKIPPED**. Any match → **WARNING**. Else **PASS**


### Requirement: `7.5.dns_health` scoring
In 7.5 Cluster Health, ``7.5.dns_health`` SHALL evaluate DNS operator Available True. Status matrix: Missing → **SKIPPED**. True → **PASS**. Else **WARNING**. Source function: ``_evaluate_health_dns``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.dns_health` matrix
- GIVEN collected data for ``7.5.dns_health``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. True → **PASS**. Else **WARNING**


### Requirement: `7.5.alerts` scoring
In 7.5 Cluster Health, ``7.5.alerts`` SHALL evaluate Firing alerts object missing. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_firing_alerts``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.alerts` matrix
- GIVEN collected data for ``7.5.alerts``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.5.alerts.firing` scoring
In 7.5 Cluster Health, ``7.5.alerts.firing`` SHALL evaluate Empty alert list. Status matrix: **PASS** (only if list empty; otherwise this id is not used). Source function: ``_evaluate_firing_alerts``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.alerts.firing` matrix
- GIVEN collected data for ``7.5.alerts.firing``
- WHEN the category evaluator runs
- THEN the status follows: **PASS** (only if list empty; otherwise this id is not used)


### Requirement: `7.5.alerts.critical` scoring
In 7.5 Cluster Health, ``7.5.alerts.critical`` SHALL evaluate severity critical. Status matrix: Any → **FAIL**. Else **PASS**. Source function: ``_evaluate_firing_alerts``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.alerts.critical` matrix
- GIVEN collected data for ``7.5.alerts.critical``
- WHEN the category evaluator runs
- THEN the status follows: Any → **FAIL**. Else **PASS**


### Requirement: `7.5.alerts.warning` scoring
In 7.5 Cluster Health, ``7.5.alerts.warning`` SHALL evaluate severity warning. Status matrix: Any → **WARNING**. Else **PASS**. Source function: ``_evaluate_firing_alerts``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.alerts.warning` matrix
- GIVEN collected data for ``7.5.alerts.warning``
- WHEN the category evaluator runs
- THEN the status follows: Any → **WARNING**. Else **PASS**


### Requirement: `7.5.alerts.info` scoring
In 7.5 Cluster Health, ``7.5.alerts.info`` SHALL evaluate severity info. Status matrix: Emitted only if any; **INFO**. Source function: ``_evaluate_firing_alerts``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.alerts.info` matrix
- GIVEN collected data for ``7.5.alerts.info``
- WHEN the category evaluator runs
- THEN the status follows: Emitted only if any; **INFO**


### Requirement: `7.5.pods` scoring
In 7.5 Cluster Health, ``7.5.pods`` SHALL evaluate pods_all missing. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_pod_health``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.pods` matrix
- GIVEN collected data for ``7.5.pods``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.5.pods.failed` scoring
In 7.5 Cluster Health, ``7.5.pods.failed`` SHALL evaluate Phase Failed/Unknown. Status matrix: Any → **WARNING** (id used instead of `.pods.health`). Source function: ``_evaluate_pod_health``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.pods.failed` matrix
- GIVEN collected data for ``7.5.pods.failed``
- WHEN the category evaluator runs
- THEN the status follows: Any → **WARNING** (id used instead of `.pods.health`)


### Requirement: `7.5.pods.health` scoring
In 7.5 Cluster Health, ``7.5.pods.health`` SHALL evaluate No Failed/Unknown. Status matrix: **PASS**. Source function: ``_evaluate_pod_health``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.pods.health` matrix
- GIVEN collected data for ``7.5.pods.health``
- WHEN the category evaluator runs
- THEN the status follows: **PASS**


### Requirement: `7.5.pods.crashloop` scoring
In 7.5 Cluster Health, ``7.5.pods.crashloop`` SHALL evaluate Waiting reason CrashLoopBackOff. Status matrix: Any → **FAIL**. Else **PASS**. Source function: ``_evaluate_pod_health``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.pods.crashloop` matrix
- GIVEN collected data for ``7.5.pods.crashloop``
- WHEN the category evaluator runs
- THEN the status follows: Any → **FAIL**. Else **PASS**


### Requirement: `7.5.node.{short}.utilization` scoring
In 7.5 Cluster Health, ``7.5.node.{short}.utilization`` SHALL evaluate `oc adm top nodes` CPU% / mem%. Status matrix: CPU>**80** or mem>**85** → **WARNING**. CPU>**60** or mem>**70** → **INFO**. Else **PASS**. Unparseable → parent N/A. Source function: ``_parse_top_node_line``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.node.{short}.utilization` matrix
- GIVEN collected data for ``7.5.node.{short}.utilization``
- WHEN the category evaluator runs
- THEN the status follows: CPU>**80** or mem>**85** → **WARNING**. CPU>**60** or mem>**70** → **INFO**. Else **PASS**. Unparseable → parent N/A


### Requirement: `7.5.master_taints` scoring
In 7.5 Cluster Health, ``7.5.master_taints`` SHALL evaluate Control-plane NoSchedule taint with key containing `master`. Status matrix: All have taint → **PASS**. Compact (every node master+worker) missing taint → **INFO**. Else **WARNING**. Source function: ``_evaluate_master_taints``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.master_taints` matrix
- GIVEN collected data for ``7.5.master_taints``
- WHEN the category evaluator runs
- THEN the status follows: All have taint → **PASS**. Compact (every node master+worker) missing taint → **INFO**. Else **WARNING**


### Requirement: `7.5.k8s_version` scoring
In 7.5 Cluster Health, ``7.5.k8s_version`` SHALL evaluate Unique kubelet versions. Status matrix: >1 → **WARNING**. Else **PASS**. Source function: ``_evaluate_k8s_version``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.k8s_version` matrix
- GIVEN collected data for ``7.5.k8s_version``
- WHEN the category evaluator runs
- THEN the status follows: >1 → **WARNING**. Else **PASS**


### Requirement: `7.5.pruning.pods` scoring
In 7.5 Cluster Health, ``7.5.pruning.pods`` SHALL evaluate Succeeded > **200** or Failed > **50**. Status matrix: True → **WARNING**. Else **PASS**. Omitted if pods missing. Source function: ``_evaluate_pruning``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.pruning.pods` matrix
- GIVEN collected data for ``7.5.pruning.pods``
- WHEN the category evaluator runs
- THEN the status follows: True → **WARNING**. Else **PASS**. Omitted if pods missing


### Requirement: `7.5.pruning.jobs` scoring
In 7.5 Cluster Health, ``7.5.pruning.jobs`` SHALL evaluate Orphan completed jobs > **100**. Status matrix: True → **WARNING**. Else **PASS**. Omitted if jobs missing. Source function: ``_evaluate_pruning``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.5.pruning.jobs` matrix
- GIVEN collected data for ``7.5.pruning.jobs``
- WHEN the category evaluator runs
- THEN the status follows: True → **WARNING**. Else **PASS**. Omitted if jobs missing


### Requirement: `7.6.cluster_quota` scoring
In 7.6 Day-2 Operations, ``7.6.cluster_quota`` SHALL evaluate ResourceQuota items. Status matrix: Items → **PASS**. Empty or missing → **NOT_APPLICABLE**. Source function: ``_evaluate_day2_quota_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.cluster_quota` matrix
- GIVEN collected data for ``7.6.cluster_quota``
- WHEN the category evaluator runs
- THEN the status follows: Items → **PASS**. Empty or missing → **NOT_APPLICABLE**


### Requirement: `7.6.req_limits` scoring
In 7.6 Day-2 Operations, ``7.6.req_limits`` SHALL evaluate LimitRanges. Status matrix: Missing collect → **SKIPPED**. None → **INFO**. Some → **PASS**. Source function: ``_evaluate_day2_quota_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.req_limits` matrix
- GIVEN collected data for ``7.6.req_limits``
- WHEN the category evaluator runs
- THEN the status follows: Missing collect → **SKIPPED**. None → **INFO**. Some → **PASS**


### Requirement: `7.6.node_expected` scoring
In 7.6 Day-2 Operations, ``7.6.node_expected`` SHALL evaluate Capacity planning. Status matrix: Always **SKIPPED**. Source function: ``_evaluate_day2_capacity_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.node_expected` matrix
- GIVEN collected data for ``7.6.node_expected``
- WHEN the category evaluator runs
- THEN the status follows: Always **SKIPPED**


### Requirement: `7.6.pv_usage` scoring
In 7.6 Day-2 Operations, ``7.6.pv_usage`` SHALL evaluate PV phases. Status matrix: Missing → **SKIPPED**. Else always **PASS**. Source function: ``_evaluate_day2_capacity_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.pv_usage` matrix
- GIVEN collected data for ``7.6.pv_usage``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Else always **PASS**


### Requirement: `7.6.prune.builds` scoring
In 7.6 Day-2 Operations, ``7.6.prune.builds`` SHALL evaluate Build pruning. Status matrix: Always **PASS**. Source function: ``_evaluate_day2_pruning``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.prune.builds` matrix
- GIVEN collected data for ``7.6.prune.builds``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS**


### Requirement: `7.6.prune.netpol` / `.prune.gc` scoring
In 7.6 Day-2 Operations, ``7.6.prune.netpol` / `.prune.gc`` SHALL evaluate Netpol / kubelet GC. Status matrix: Always **SKIPPED**. Source function: ``_evaluate_day2_pruning``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.prune.netpol` / `.prune.gc` matrix
- GIVEN collected data for ``7.6.prune.netpol` / `.prune.gc``
- WHEN the category evaluator runs
- THEN the status follows: Always **SKIPPED**


### Requirement: `7.6.prune.ns` scoring
In 7.6 Day-2 Operations, ``7.6.prune.ns`` SHALL evaluate Namespace count. Status matrix: **> 100** → **WARNING**. Else **PASS** (0 if namespaces missing). Source function: ``_evaluate_day2_pruning``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.prune.ns` matrix
- GIVEN collected data for ``7.6.prune.ns``
- WHEN the category evaluator runs
- THEN the status follows: **> 100** → **WARNING**. Else **PASS** (0 if namespaces missing)


### Requirement: `7.6.infra_nodes` scoring
In 7.6 Day-2 Operations, ``7.6.infra_nodes`` SHALL evaluate Label `node-role.kubernetes.io/infra`. Status matrix: Missing nodes → **SKIPPED**. Any infra → **PASS**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_day2_infra_nodes``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.infra_nodes` matrix
- GIVEN collected data for ``7.6.infra_nodes``
- WHEN the category evaluator runs
- THEN the status follows: Missing nodes → **SKIPPED**. Any infra → **PASS**. Else **NOT_APPLICABLE**


### Requirement: `7.6.update_impact` / `.alert_receivers` / `.remote_health` scoring
In 7.6 Day-2 Operations, ``7.6.update_impact` / `.alert_receivers` / `.remote_health`` SHALL evaluate Not collected. Status matrix: Always **SKIPPED**. Source function: ``_evaluate_day2_image_and_alert_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.update_impact` / `.alert_receivers` / `.remote_health` matrix
- GIVEN collected data for ``7.6.update_impact` / `.alert_receivers` / `.remote_health``
- WHEN the category evaluator runs
- THEN the status follows: Always **SKIPPED**


### Requirement: `7.6.image_mgmt` scoring
In 7.6 Day-2 Operations, ``7.6.image_mgmt`` SHALL evaluate Image registry allow/block lists. Status matrix: Missing → **SKIPPED**. Else **INFO**. Source function: ``_evaluate_day2_image_and_alert_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.image_mgmt` matrix
- GIVEN collected data for ``7.6.image_mgmt``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Else **INFO**


### Requirement: `7.6.csr_pending` scoring
In 7.6 Day-2 Operations, ``7.6.csr_pending`` SHALL evaluate Pending CSRs. Status matrix: Missing → **SKIPPED**. Any pending → **WARNING**. Else **PASS**. Source function: ``_evaluate_day2_cert_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.csr_pending` matrix
- GIVEN collected data for ``7.6.csr_pending``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Any pending → **WARNING**. Else **PASS**


### Requirement: `7.6.custom_certs` scoring
In 7.6 Day-2 Operations, ``7.6.custom_certs`` SHALL evaluate Certificate resources. Status matrix: Always **PASS** (count or “using default”). Source function: ``_evaluate_day2_cert_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.custom_certs` matrix
- GIVEN collected data for ``7.6.custom_certs``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS** (count or “using default”)


### Requirement: `7.6.node_ssh` scoring
In 7.6 Day-2 Operations, ``7.6.node_ssh`` SHALL evaluate SSH. Status matrix: Always **SKIPPED**. Source function: ``_evaluate_day2_cert_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.node_ssh` matrix
- GIVEN collected data for ``7.6.node_ssh``
- WHEN the category evaluator runs
- THEN the status follows: Always **SKIPPED**


### Requirement: `7.6.mcp_max_unavailable` scoring
In 7.6 Day-2 Operations, ``7.6.mcp_max_unavailable`` SHALL evaluate MCP `maxUnavailable`. Status matrix: Missing → **SKIPPED**. Else always **PASS**. Source function: ``_evaluate_day2_mcp_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.mcp_max_unavailable` matrix
- GIVEN collected data for ``7.6.mcp_max_unavailable``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Else always **PASS**


### Requirement: `7.6.proxy` scoring
In 7.6 Day-2 Operations, ``7.6.proxy`` SHALL evaluate Cluster proxy URLs. Status matrix: Missing → N/A. Proxy set → **INFO**. Else **PASS**. Source function: ``_evaluate_proxy``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.proxy` matrix
- GIVEN collected data for ``7.6.proxy``
- WHEN the category evaluator runs
- THEN the status follows: Missing → N/A. Proxy set → **INFO**. Else **PASS**


### Requirement: `7.6.rq` scoring
In 7.6 Day-2 Operations, ``7.6.rq`` SHALL evaluate ResourceQuota. Status matrix: Collect fail → **SKIPPED**. Zero quotas → **INFO**. Else **PASS**. Source function: ``_evaluate_resource_quotas``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.rq` matrix
- GIVEN collected data for ``7.6.rq``
- WHEN the category evaluator runs
- THEN the status follows: Collect fail → **SKIPPED**. Zero quotas → **INFO**. Else **PASS**


### Requirement: `7.6.upgrade.history` scoring
In 7.6 Day-2 Operations, ``7.6.upgrade.history`` SHALL evaluate Completed history. Status matrix: None → **NOT_APPLICABLE**. Else **PASS**. Source function: ``_evaluate_upgrade_history``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.upgrade.history` matrix
- GIVEN collected data for ``7.6.upgrade.history``
- WHEN the category evaluator runs
- THEN the status follows: None → **NOT_APPLICABLE**. Else **PASS**


### Requirement: `7.6.apiserver.tls` scoring
In 7.6 Day-2 Operations, ``7.6.apiserver.tls`` SHALL evaluate `tlsSecurityProfile.type`. Status matrix: Empty → **PASS**. `Old` → **WARNING**. `Custom` → **INFO**. Else **PASS**. Source function: ``_evaluate_apiserver_config``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.apiserver.tls` matrix
- GIVEN collected data for ``7.6.apiserver.tls``
- WHEN the category evaluator runs
- THEN the status follows: Empty → **PASS**. `Old` → **WARNING**. `Custom` → **INFO**. Else **PASS**


### Requirement: `7.6.apiserver.audit` scoring
In 7.6 Day-2 Operations, ``7.6.apiserver.audit`` SHALL evaluate `audit.profile`. Status matrix: `None` → **WARNING**. WriteRequestBodies/AllRequestBodies → **PASS**. Else **PASS**. Source function: ``_evaluate_apiserver_config``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.apiserver.audit` matrix
- GIVEN collected data for ``7.6.apiserver.audit``
- WHEN the category evaluator runs
- THEN the status follows: `None` → **WARNING**. WriteRequestBodies/AllRequestBodies → **PASS**. Else **PASS**


### Requirement: `7.6.namespaces` scoring
In 7.6 Day-2 Operations, ``7.6.namespaces`` SHALL evaluate User namespaces (not openshift-/kube- prefixes). Status matrix: **> 50** user NS → **WARNING**. Else **PASS**. Source function: ``_evaluate_namespaces``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.namespaces` matrix
- GIVEN collected data for ``7.6.namespaces``
- WHEN the category evaluator runs
- THEN the status follows: **> 50** user NS → **WARNING**. Else **PASS**


### Requirement: `7.6.limitranges` scoring
In 7.6 Day-2 Operations, ``7.6.limitranges`` SHALL evaluate LimitRange. Status matrix: Collect fail → **SKIPPED**. None → **INFO**. Else **PASS**. Source function: ``_evaluate_limit_ranges``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.limitranges` matrix
- GIVEN collected data for ``7.6.limitranges``
- WHEN the category evaluator runs
- THEN the status follows: Collect fail → **SKIPPED**. None → **INFO**. Else **PASS**


### Requirement: `7.6.op_approval` scoring
In 7.6 Day-2 Operations, ``7.6.op_approval`` SHALL evaluate Automatic installPlanApproval. Status matrix: See Shared helpers. Source function: ``_evaluate_operator_approval``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.op_approval` matrix
- GIVEN collected data for ``7.6.op_approval``
- WHEN the category evaluator runs
- THEN the status follows: See Shared helpers


### Requirement: `7.6.deploymentconfigs` scoring
In 7.6 Day-2 Operations, ``7.6.deploymentconfigs`` SHALL evaluate DeploymentConfig items. Status matrix: Missing → **NOT_APPLICABLE**. Empty items → **PASS**. Any DC → **WARNING**. Source function: ``_evaluate_deploymentconfigs``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.deploymentconfigs` matrix
- GIVEN collected data for ``7.6.deploymentconfigs``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **NOT_APPLICABLE**. Empty items → **PASS**. Any DC → **WARNING**


### Requirement: `7.6.storage.*` scoring
In 7.6 Day-2 Operations, ``7.6.storage.*`` SHALL evaluate Same as 7.3 storage helpers. Status matrix: Same matrices; ids prefixed `7.6`. Source function: ``_evaluate_storage``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.6.storage.*` matrix
- GIVEN collected data for ``7.6.storage.*``
- WHEN the category evaluator runs
- THEN the status follows: Same matrices; ids prefixed `7.6`


### Requirement: `7.7.container_security` scoring
In 7.7 Security and Compliance, ``7.7.container_security`` SHALL evaluate SCC list present. Status matrix: Missing → **SKIPPED**. Else **PASS**. Source function: ``_evaluate_tsr_security_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.container_security` matrix
- GIVEN collected data for ``7.7.container_security``
- WHEN the category evaluator runs
- THEN the status follows: Missing → **SKIPPED**. Else **PASS**


### Requirement: `7.7.auditing` scoring
In 7.7 Security and Compliance, ``7.7.auditing`` SHALL evaluate APIServer audit profile. Status matrix: Data missing → **PASS** (“default”). `None` → **WARNING**. Else **PASS**. Source function: ``_evaluate_tsr_security_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.auditing` matrix
- GIVEN collected data for ``7.7.auditing``
- WHEN the category evaluator runs
- THEN the status follows: Data missing → **PASS** (“default”). `None` → **WARNING**. Else **PASS**


### Requirement: `7.7.encryption` scoring
In 7.7 Security and Compliance, ``7.7.encryption`` SHALL evaluate `spec.encryption.type`. Status matrix: `aescbc` or `aesgcm` → **PASS**. Other non-empty → **INFO**. Empty → **INFO** (identity). Source function: ``_evaluate_tsr_security_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.encryption` matrix
- GIVEN collected data for ``7.7.encryption``
- WHEN the category evaluator runs
- THEN the status follows: `aescbc` or `aesgcm` → **PASS**. Other non-empty → **INFO**. Empty → **INFO** (identity)


### Requirement: `7.7.vuln_scan` scoring
In 7.7 Security and Compliance, ``7.7.vuln_scan`` SHALL evaluate Compliance scans object. Status matrix: Present → **PASS**. Else **NOT_APPLICABLE**. Source function: ``_evaluate_tsr_security_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.vuln_scan` matrix
- GIVEN collected data for ``7.7.vuln_scan``
- WHEN the category evaluator runs
- THEN the status follows: Present → **PASS**. Else **NOT_APPLICABLE**


### Requirement: `7.7.tls_profile` scoring
In 7.7 Security and Compliance, ``7.7.tls_profile`` SHALL evaluate TLS profile type (default Intermediate). Status matrix: Always **INFO**. Source function: ``_evaluate_tsr_security_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.tls_profile` matrix
- GIVEN collected data for ``7.7.tls_profile``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO**


### Requirement: `7.7.psa` scoring
In 7.7 Security and Compliance, ``7.7.psa`` SHALL evaluate PSA labels on namespaces. Status matrix: Always **PASS** (even if data missing). Source function: ``_evaluate_tsr_security_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.psa` matrix
- GIVEN collected data for ``7.7.psa``
- WHEN the category evaluator runs
- THEN the status follows: Always **PASS** (even if data missing)


### Requirement: `7.7.file_integrity` scoring
In 7.7 Security and Compliance, ``7.7.file_integrity`` SHALL evaluate FIO. Status matrix: Always **NOT_APPLICABLE**. Source function: ``_evaluate_tsr_security_aggregate``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.file_integrity` matrix
- GIVEN collected data for ``7.7.file_integrity``
- WHEN the category evaluator runs
- THEN the status follows: Always **NOT_APPLICABLE**


### Requirement: `7.7.scc.custom` scoring
In 7.7 Security and Compliance, ``7.7.scc.custom`` SHALL evaluate SCC names not in `_DEFAULT_SCCS`. Status matrix: Any custom → **WARNING**. Else **PASS**. Source function: ``_evaluate_scc``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.scc.custom` matrix
- GIVEN collected data for ``7.7.scc.custom``
- WHEN the category evaluator runs
- THEN the status follows: Any custom → **WARNING**. Else **PASS**


### Requirement: `7.7.scc.privileged_users` scoring
In 7.7 Security and Compliance, ``7.7.scc.privileged_users`` SHALL evaluate privileged SCC users not `system:`. Status matrix: Any → **WARNING**. Else **PASS**. Omitted if no privileged SCC. Source function: ``_evaluate_scc``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.scc.privileged_users` matrix
- GIVEN collected data for ``7.7.scc.privileged_users``
- WHEN the category evaluator runs
- THEN the status follows: Any → **WARNING**. Else **PASS**. Omitted if no privileged SCC


### Requirement: `7.7.oauth.idp` scoring
In 7.7 Security and Compliance, ``7.7.oauth.idp`` SHALL evaluate Identity providers. Status matrix: None → **WARNING**. Else **PASS**. Source function: ``_evaluate_oauth``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.oauth.idp` matrix
- GIVEN collected data for ``7.7.oauth.idp``
- WHEN the category evaluator runs
- THEN the status follows: None → **WARNING**. Else **PASS**


### Requirement: `7.7.rbac.cluster_admin` scoring
In 7.7 Security and Compliance, ``7.7.rbac.cluster_admin`` SHALL evaluate Non-system cluster-admin subjects. Status matrix: **> 5** → **WARNING**. Else **PASS**. Source function: ``_evaluate_rbac``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.rbac.cluster_admin` matrix
- GIVEN collected data for ``7.7.rbac.cluster_admin``
- WHEN the category evaluator runs
- THEN the status follows: **> 5** → **WARNING**. Else **PASS**


### Requirement: `7.7.compliance` scoring
In 7.7 Security and Compliance, ``7.7.compliance`` SHALL evaluate Scan/suite missing. Status matrix: Both missing → **NOT_APPLICABLE**. Scan phase not DONE/empty → **WARNING**. Else **PASS**. Source function: ``_evaluate_compliance``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.compliance` matrix
- GIVEN collected data for ``7.7.compliance``
- WHEN the category evaluator runs
- THEN the status follows: Both missing → **NOT_APPLICABLE**. Scan phase not DONE/empty → **WARNING**. Else **PASS**


### Requirement: `7.7.csr` scoring
In 7.7 Security and Compliance, ``7.7.csr`` SHALL evaluate Denied / pending CSRs. Status matrix: Denied → **FAIL**. Pending → **WARNING**. Else **PASS**. Source function: ``_evaluate_csr``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.7.csr` matrix
- GIVEN collected data for ``7.7.csr``
- WHEN the category evaluator runs
- THEN the status follows: Denied → **FAIL**. Pending → **WARNING**. Else **PASS**


### Requirement: `7.8.node_alloc` scoring
In 7.8 Performance Metrics, ``7.8.node_alloc`` SHALL evaluate No node maps. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_prometheus_node_metrics``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.node_alloc` matrix
- GIVEN collected data for ``7.8.node_alloc``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.8.node.{short}.alloc` scoring
In 7.8 Performance Metrics, ``7.8.node.{short}.alloc`` SHALL evaluate CPU req%, mem req%, mem WSS%. Status matrix: CPU req > **90** or mem req > **90** or WSS > **85** → **WARNING**. Else **PASS**. Limits are informational only. Source function: ``_build_node_alloc_check``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.node.{short}.alloc` matrix
- GIVEN collected data for ``7.8.node.{short}.alloc``
- WHEN the category evaluator runs
- THEN the status follows: CPU req > **90** or mem req > **90** or WSS > **85** → **WARNING**. Else **PASS**. Limits are informational only


### Requirement: `7.8.etcd.wal` scoring
In 7.8 Performance Metrics, ``7.8.etcd.wal`` SHALL evaluate No WAL vector. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_etcd_wal_fsync``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.etcd.wal` matrix
- GIVEN collected data for ``7.8.etcd.wal``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.8.etcd.wal.{pod}` scoring
In 7.8 Performance Metrics, ``7.8.etcd.wal.{pod}`` SHALL evaluate WAL fsync P99 (seconds×1000). Status matrix: **> 50** ms → **FAIL**. **> 10** ms → **WARNING**. Else **PASS**. Source function: ``_evaluate_etcd_wal_fsync``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.etcd.wal.{pod}` matrix
- GIVEN collected data for ``7.8.etcd.wal.{pod}``
- WHEN the category evaluator runs
- THEN the status follows: **> 50** ms → **FAIL**. **> 10** ms → **WARNING**. Else **PASS**


### Requirement: `7.8.etcd.backend.{pod}` scoring
In 7.8 Performance Metrics, ``7.8.etcd.backend.{pod}`` SHALL evaluate Backend commit P99. Status matrix: **> 50** ms → **FAIL**. **> 25** ms → **WARNING**. Else **PASS**. Source function: ``_evaluate_etcd_backend_commit``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.etcd.backend.{pod}` matrix
- GIVEN collected data for ``7.8.etcd.backend.{pod}``
- WHEN the category evaluator runs
- THEN the status follows: **> 50** ms → **FAIL**. **> 25** ms → **WARNING**. Else **PASS**


### Requirement: `7.8.etcd.leader` scoring
In 7.8 Performance Metrics, ``7.8.etcd.leader`` SHALL evaluate No leader-change vector. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_etcd_leader_changes``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.etcd.leader` matrix
- GIVEN collected data for ``7.8.etcd.leader``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.8.etcd.leader_changes` scoring
In 7.8 Performance Metrics, ``7.8.etcd.leader_changes`` SHALL evaluate Sum of increases last hour. Status matrix: **> 3** → **WARNING**. **> 0** → **INFO**. **0** → **PASS**. Source function: ``_evaluate_etcd_leader_changes``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.etcd.leader_changes` matrix
- GIVEN collected data for ``7.8.etcd.leader_changes``
- WHEN the category evaluator runs
- THEN the status follows: **> 3** → **WARNING**. **> 0** → **INFO**. **0** → **PASS**


### Requirement: `7.8.etcd.db.{pod}` scoring
In 7.8 Performance Metrics, ``7.8.etcd.db.{pod}`` SHALL evaluate DB size bytes / 1024². Status matrix: **> 8192** MiB → **FAIL**. **> 4096** MiB → **WARNING**. Else **PASS**. Source function: ``_evaluate_etcd_db_size``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.etcd.db.{pod}` matrix
- GIVEN collected data for ``7.8.etcd.db.{pod}``
- WHEN the category evaluator runs
- THEN the status follows: **> 8192** MiB → **FAIL**. **> 4096** MiB → **WARNING**. Else **PASS**


### Requirement: `7.8.etcd.proposals` scoring
In 7.8 Performance Metrics, ``7.8.etcd.proposals`` SHALL evaluate Failed proposals last hour. Status matrix: **> 0** → **WARNING**. **0** → **PASS**. Empty vector → no row. Source function: ``_evaluate_etcd_proposals``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.etcd.proposals` matrix
- GIVEN collected data for ``7.8.etcd.proposals``
- WHEN the category evaluator runs
- THEN the status follows: **> 0** → **WARNING**. **0** → **PASS**. Empty vector → no row


### Requirement: `7.8.apiserver.latency` scoring
In 7.8 Performance Metrics, ``7.8.apiserver.latency`` SHALL evaluate Max P99 among series. Status matrix: **> 1000** ms → **FAIL**. **> 500** ms → **WARNING**. Else **PASS**. No series → N/A. Source function: ``_evaluate_apiserver_latency``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.apiserver.latency` matrix
- GIVEN collected data for ``7.8.apiserver.latency``
- WHEN the category evaluator runs
- THEN the status follows: **> 1000** ms → **FAIL**. **> 500** ms → **WARNING**. Else **PASS**. No series → N/A


### Requirement: `7.8.apiserver.errors` scoring
In 7.8 Performance Metrics, ``7.8.apiserver.errors`` SHALL evaluate Sum 5xx rate. Status matrix: **> 1.0** req/s → **WARNING**. Else **PASS**. No series → no row. Source function: ``_evaluate_apiserver_latency``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.apiserver.errors` matrix
- GIVEN collected data for ``7.8.apiserver.errors``
- WHEN the category evaluator runs
- THEN the status follows: **> 1.0** req/s → **WARNING**. Else **PASS**. No series → no row


### Requirement: `7.8.etcd.endpoint_health` scoring
In 7.8 Performance Metrics, ``7.8.etcd.endpoint_health`` SHALL evaluate etcdctl health JSON. Status matrix: Any `health` false → **FAIL**. Else **PASS**. Bad/missing → no row. Source function: ``_check_etcd_endpoint_health``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.etcd.endpoint_health` matrix
- GIVEN collected data for ``7.8.etcd.endpoint_health``
- WHEN the category evaluator runs
- THEN the status follows: Any `health` false → **FAIL**. Else **PASS**. Bad/missing → no row


### Requirement: `7.8.etcd.endpoint_status` scoring
In 7.8 Performance Metrics, ``7.8.etcd.endpoint_status`` SHALL evaluate Member count. Status matrix: **≠ 3** → **WARNING**. **3** → **PASS**. Source function: ``_check_etcd_endpoint_dbsize``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.etcd.endpoint_status` matrix
- GIVEN collected data for ``7.8.etcd.endpoint_status``
- WHEN the category evaluator runs
- THEN the status follows: **≠ 3** → **WARNING**. **3** → **PASS**


### Requirement: `7.8.pvc.util.critical` scoring
In 7.8 Performance Metrics, ``7.8.pvc.util.critical`` SHALL evaluate Utilization **> 90%**. Status matrix: Any → **FAIL**. Source function: ``_evaluate_pvc_utilization``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.pvc.util.critical` matrix
- GIVEN collected data for ``7.8.pvc.util.critical``
- WHEN the category evaluator runs
- THEN the status follows: Any → **FAIL**


### Requirement: `7.8.pvc.util.warning` scoring
In 7.8 Performance Metrics, ``7.8.pvc.util.warning`` SHALL evaluate **> 75** and ≤90. Status matrix: Any → **WARNING**. Source function: ``_evaluate_pvc_utilization``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.pvc.util.warning` matrix
- GIVEN collected data for ``7.8.pvc.util.warning``
- WHEN the category evaluator runs
- THEN the status follows: Any → **WARNING**


### Requirement: `7.8.pvc.util.ok` scoring
In 7.8 Performance Metrics, ``7.8.pvc.util.ok`` SHALL evaluate All ≤75. Status matrix: **PASS** only if no critical and no warning. Source function: ``_evaluate_pvc_utilization``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.8.pvc.util.ok` matrix
- GIVEN collected data for ``7.8.pvc.util.ok``
- WHEN the category evaluator runs
- THEN the status follows: **PASS** only if no critical and no warning


### Requirement: `7.9.hw` scoring
In 7.9 Hardware Inventory, ``7.9.hw`` SHALL evaluate No `node_hw_*` files. Status matrix: **NOT_APPLICABLE**. Source function: ``_evaluate_node_hardware_inventory``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.9.hw` matrix
- GIVEN collected data for ``7.9.hw``
- WHEN the category evaluator runs
- THEN the status follows: **NOT_APPLICABLE**


### Requirement: `7.9.{key}` scoring
In 7.9 Hardware Inventory, ``7.9.{key}`` SHALL evaluate Collect error on a node_hw file. Status matrix: **SKIPPED**. Source function: ``_evaluate_node_hardware_inventory``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.9.{key}` matrix
- GIVEN collected data for ``7.9.{key}``
- WHEN the category evaluator runs
- THEN the status follows: **SKIPPED**


### Requirement: `7.9.hw.{short}.identity` / `.cpu` / `.memory` scoring
In 7.9 Hardware Inventory, ``7.9.hw.{short}.identity` / `.cpu` / `.memory`` SHALL evaluate Inventory fields. Status matrix: Always **INFO**. Source function: ``_build_hw_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.9.hw.{short}.identity` / `.cpu` / `.memory` matrix
- GIVEN collected data for ``7.9.hw.{short}.identity` / `.cpu` / `.memory``
- WHEN the category evaluator runs
- THEN the status follows: Always **INFO**


### Requirement: `7.9.hw.{short}.disk` scoring
In 7.9 Hardware Inventory, ``7.9.hw.{short}.disk`` SHALL evaluate Any disk `rotational` true. Status matrix: Yes → **WARNING**. Else **PASS**. Omitted if no disks. Source function: ``_build_hw_checks``. If `hc-report-engine` overrides this check, the override wins.

#### Scenario: `7.9.hw.{short}.disk` matrix
- GIVEN collected data for ``7.9.hw.{short}.disk``
- WHEN the category evaluator runs
- THEN the status follows: Yes → **WARNING**. Else **PASS**. Omitted if no disks

