# Live collection

## Purpose

Read-only `oc` collection for the health-check snapshot on `main`. Output is the JSON tree that `hc-report-engine` loads. Offline `omc` collection is `hc-supportshell`. Shared scripts `03` through `09` are the same files as supportshell and call `$HC_CLI`.

## Requirements

### Requirement: Live driver
`scripts/health_check/collect/hc_collect.sh` SHALL collect read-only cluster JSON with `oc`. It SHALL accept `--kubeconfig`, `--output-dir`, and `--categories`. `make hc-collect` SHALL pass `--output-dir output/hc_collect` unless `HC_COLLECT_OUT` is set. A missing `oc` binary or a failed `oc cluster-info` SHALL exit 1. Category script failures SHALL NOT abort the run. The driver SHALL exit 0 after writing `manifest.json` even when some captures failed.

#### Scenario: Unreachable cluster fails
- GIVEN `oc` cannot reach the API
- WHEN the live driver starts
- THEN it exits 1
- AND it does not write a manifest

#### Scenario: Category errors still finish
- GIVEN one category script exits non-zero
- WHEN the driver runs the full script list
- THEN later category scripts still run
- AND the process exits 0
- AND `manifest.json` exists


### Requirement: Capture envelopes
Each capture SHALL write `<category>/<check_name>.json` and `<check_name>.meta.json`. Success SHALL store the raw `oc -o json` document. An empty list SHALL store `_hc_not_found` with exit code 0 and a note that the resource returned an empty list. A missing CRD (`the server doesn't have a resource type`) SHALL store `_hc_not_found` with exit code 1 and a note that the operator is not installed. Any other `oc` failure SHALL store `_hc_error` and SHALL increment the error count. Text captures SHALL store `_hc_text` with `command`, `output`, and `exit_code`. The sidecar SHALL record `command`, `script`, `chapter`, `category`, `check_name`, and `timestamp`. Collection SHALL NOT require jq or Python.

#### Scenario: Missing CRD is not a hard error
- GIVEN `oc` reports that the server does not have that resource type
- WHEN `hc_capture_json` runs
- THEN the JSON contains `_hc_not_found` true
- AND the category script continues

#### Scenario: Other oc failures are error envelopes
- GIVEN `oc` fails for a reason other than a missing resource type
- WHEN `hc_capture_json` runs
- THEN the JSON contains `_hc_error` true
- AND a `.meta.json` sidecar is written


### Requirement: Manifest
`manifest.json` SHALL contain `timestamp` in UTC `YYYY-MM-DDTHH:MM:SSZ`, `cluster_server`, `output_dir`, `total_files`, `total_errors`, `categories`, and `files`. `files` SHALL list relative paths of `*.json` except `manifest.json` and `*.meta.json`, sorted. `total_files` SHALL count non-sidecar JSON files under the category directories that ran.

#### Scenario: Manifest lists captured files
- GIVEN at least one successful capture
- WHEN the driver finishes
- THEN `manifest.json` `files` contains that relative JSON path
- AND it does not contain `manifest.json` or a `.meta.json` path


### Requirement: Live captures in 03_base_platform.sh
`03_base_platform.sh` SHALL run in category `03_base_platform` and SHALL capture the check names in the scenarios.

#### Scenario: 03_base_platform clusterversion
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/clusterversion.json` with `hc_capture_json`
- AND the command is `get clusterversion`

#### Scenario: 03_base_platform clusteroperators
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/clusteroperators.json` with `hc_capture_json`
- AND the command is `get clusteroperator`

#### Scenario: 03_base_platform subscriptions
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/subscriptions.json` with `hc_capture_json`
- AND the command is `get subscription -A`

#### Scenario: 03_base_platform csv
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/csv.json` with `hc_capture_json`
- AND the command is `get csv -A`

#### Scenario: 03_base_platform infrastructure
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/infrastructure.json` with `hc_capture_json`
- AND the command is `get infrastructure cluster`

#### Scenario: 03_base_platform install_config
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/install_config.json` with `hc_capture_json`
- AND the command is `get configmap cluster-config-v1 -n kube-system`

#### Scenario: 03_base_platform scheduler
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/scheduler.json` with `hc_capture_json`
- AND the command is `get scheduler cluster`

#### Scenario: 03_base_platform proxy
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/proxy.json` with `hc_capture_json`
- AND the command is `get proxy cluster`

#### Scenario: 03_base_platform nodes
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/nodes.json` with `hc_capture_json`
- AND the command is `get nodes`

#### Scenario: 03_base_platform nodes_wide
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/nodes_wide.json` with `hc_capture_text`
- AND the command is `$HC_CLI get nodes -o wide`

#### Scenario: 03_base_platform csr
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/csr.json` with `hc_capture_json`
- AND the command is `get csr`

#### Scenario: 03_base_platform scc
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/scc.json` with `hc_capture_json`
- AND the command is `get scc`

#### Scenario: 03_base_platform oauth
- GIVEN live collection runs `03_base_platform.sh`
- WHEN that category script finishes its capture list
- THEN it writes `03_base_platform/oauth.json` with `hc_capture_json`
- AND the command is `get oauth cluster`


### Requirement: Live captures in 04_topology.sh
`04_topology.sh` SHALL run in category `04_topology` and SHALL capture the check names in the scenarios.

#### Scenario: 04_topology nodes
- GIVEN live collection runs `04_topology.sh`
- WHEN that category script finishes its capture list
- THEN it writes `04_topology/nodes.json` with `hc_capture_json`
- AND the command is `get nodes`

#### Scenario: 04_topology node_labels
- GIVEN live collection runs `04_topology.sh`
- WHEN that category script finishes its capture list
- THEN it writes `04_topology/node_labels.json` with `hc_capture_text`
- AND the command is `$HC_CLI get nodes --show-labels`

#### Scenario: 04_topology machineconfig
- GIVEN live collection runs `04_topology.sh`
- WHEN that category script finishes its capture list
- THEN it writes `04_topology/machineconfig.json` with `hc_capture_json`
- AND the command is `get machineconfig`

#### Scenario: 04_topology machineconfigpool
- GIVEN live collection runs `04_topology.sh`
- WHEN that category script finishes its capture list
- THEN it writes `04_topology/machineconfigpool.json` with `hc_capture_json`
- AND the command is `get machineconfigpool`

#### Scenario: 04_topology kubeletconfig
- GIVEN live collection runs `04_topology.sh`
- WHEN that category script finishes its capture list
- THEN it writes `04_topology/kubeletconfig.json` with `hc_capture_json`
- AND the command is `get kubeletconfig`

#### Scenario: 04_topology etcd
- GIVEN live collection runs `04_topology.sh`
- WHEN that category script finishes its capture list
- THEN it writes `04_topology/etcd.json` with `hc_capture_json`
- AND the command is `get etcd cluster`

#### Scenario: 04_topology etcd_pods
- GIVEN live collection runs `04_topology.sh`
- WHEN that category script finishes its capture list
- THEN it writes `04_topology/etcd_pods.json` with `hc_capture_json`
- AND the command is `get pods -n openshift-etcd`


### Requirement: Live captures in 05_components.sh
`05_components.sh` SHALL run in category `05_components` and SHALL capture the check names in the scenarios.

#### Scenario: 05_components cluster_operators
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/cluster_operators.json` with `hc_capture_json`
- AND the command is `get co`

#### Scenario: 05_components machineconfig
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/machineconfig.json` with `hc_capture_json`
- AND the command is `get mc`

#### Scenario: 05_components etcd_pods
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/etcd_pods.json` with `hc_capture_json`
- AND the command is `get pods -n openshift-etcd`

#### Scenario: 05_components etcd_status
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/etcd_status.json` with `hc_capture_text`
- AND the command is `$HC_CLI -n openshift-etcd get pods -o wide`

#### Scenario: 05_components imageregistry
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/imageregistry.json` with `hc_capture_json`
- AND the command is `get configs.imageregistry.operator.openshift.io cluster`

#### Scenario: 05_components prometheus
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/prometheus.json` with `hc_capture_json`
- AND the command is `get prometheus -n openshift-monitoring`

#### Scenario: 05_components prometheusrule
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/prometheusrule.json` with `hc_capture_json`
- AND the command is `get prometheusrule -n openshift-monitoring`

#### Scenario: 05_components alertmanager
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/alertmanager.json` with `hc_capture_json`
- AND the command is `get alertmanager -n openshift-monitoring`

#### Scenario: 05_components ingresscontroller
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/ingresscontroller.json` with `hc_capture_json`
- AND the command is `get ingresscontroller -n openshift-ingress-operator`

#### Scenario: 05_components storageclass
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/storageclass.json` with `hc_capture_json`
- AND the command is `get storageclass`

#### Scenario: 05_components pv
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/pv.json` with `hc_capture_json`
- AND the command is `get pv`

#### Scenario: 05_components pvc
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/pvc.json` with `hc_capture_json`
- AND the command is `get pvc -A`

#### Scenario: 05_components network
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/network.json` with `hc_capture_json`
- AND the command is `get network cluster`

#### Scenario: 05_components clusternetwork
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/clusternetwork.json` with `hc_capture_json`
- AND the command is `get clusternetwork || true`

#### Scenario: 05_components network_operator
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/network_operator.json` with `hc_capture_json`
- AND the command is `get network.operator cluster`

#### Scenario: 05_components nncp
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/nncp.json` with `hc_capture_json`
- AND the command is `get nncp || true`

#### Scenario: 05_components net_attach_def
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/net_attach_def.json` with `hc_capture_json`
- AND the command is `get net-attach-def -A || true`

#### Scenario: 05_components dns_operator
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/dns_operator.json` with `hc_capture_json`
- AND the command is `get dns.operator default`

#### Scenario: 05_components dns_config
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/dns_config.json` with `hc_capture_json`
- AND the command is `get dns cluster`

#### Scenario: 05_components crds
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/crds.json` with `hc_capture_json`
- AND the command is `get crd`

#### Scenario: 05_components apirequestcounts
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/apirequestcounts.json` with `hc_capture_json`
- AND the command is `get apirequestcounts || true`

#### Scenario: 05_components validatingwebhooks
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/validatingwebhooks.json` with `hc_capture_json`
- AND the command is `get validatingwebhookconfigurations || true`

#### Scenario: 05_components mutatingwebhooks
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/mutatingwebhooks.json` with `hc_capture_json`
- AND the command is `get mutatingwebhookconfigurations || true`

#### Scenario: 05_components monitoring_config
- GIVEN live collection runs `05_components.sh`
- WHEN that category script finishes its capture list
- THEN it writes `05_components/monitoring_config.json` with `hc_capture_json`
- AND the command is `get configmap cluster-monitoring-config -n openshift-monitoring || true`


### Requirement: Live captures in 06_layered.sh
`06_layered.sh` SHALL run in category `06_layered` and SHALL capture the check names in the scenarios.

#### Scenario: 06_layered cnv_hyperconverged
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/cnv_hyperconverged.json` with `hc_capture_json`
- AND the command is `get hyperconverged -n openshift-cnv`

#### Scenario: 06_layered cnv_kubevirt
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/cnv_kubevirt.json` with `hc_capture_json`
- AND the command is `get kubevirt -n openshift-cnv`

#### Scenario: 06_layered cnv_pods
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/cnv_pods.json` with `hc_capture_json`
- AND the command is `get pods -n openshift-cnv`

#### Scenario: 06_layered cnv_vm
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/cnv_vm.json` with `hc_capture_json`
- AND the command is `get vm -A`

#### Scenario: 06_layered cnv_vmi
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/cnv_vmi.json` with `hc_capture_json`
- AND the command is `get vmi -A`

#### Scenario: 06_layered acm_multiclusterhub
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/acm_multiclusterhub.json` with `hc_capture_json`
- AND the command is `get multiclusterhub -n open-cluster-management`

#### Scenario: 06_layered acm_pods
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/acm_pods.json` with `hc_capture_json`
- AND the command is `get pods -n open-cluster-management`

#### Scenario: 06_layered acs_central
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/acs_central.json` with `hc_capture_json`
- AND the command is `get central -n stackrox`

#### Scenario: 06_layered acs_pods
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/acs_pods.json` with `hc_capture_json`
- AND the command is `get pods -n stackrox`

#### Scenario: 06_layered logging_clusterlogging
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/logging_clusterlogging.json` with `hc_capture_json`
- AND the command is `get clusterlogging instance -n openshift-logging`

#### Scenario: 06_layered logging_loki
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/logging_loki.json` with `hc_capture_json`
- AND the command is `get lokistack -n openshift-logging`

#### Scenario: 06_layered logging_pods
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/logging_pods.json` with `hc_capture_json`
- AND the command is `get pods -n openshift-logging`

#### Scenario: 06_layered pipelines_tektonconfig
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/pipelines_tektonconfig.json` with `hc_capture_json`
- AND the command is `get tektonconfig cluster`

#### Scenario: 06_layered pipelines_pods
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/pipelines_pods.json` with `hc_capture_json`
- AND the command is `get pods -n openshift-pipelines`

#### Scenario: 06_layered servicemesh_smcp
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/servicemesh_smcp.json` with `hc_capture_json`
- AND the command is `get servicemeshcontrolplane -A`

#### Scenario: 06_layered servicemesh_pods
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/servicemesh_pods.json` with `hc_capture_json`
- AND the command is `get pods -n istio-system`

#### Scenario: 06_layered serverless_knserving
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/serverless_knserving.json` with `hc_capture_json`
- AND the command is `get knativeserving -A || true`

#### Scenario: 06_layered serverless_kneventing
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/serverless_kneventing.json` with `hc_capture_json`
- AND the command is `get knativeeventing -A || true`

#### Scenario: 06_layered quay_registry
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/quay_registry.json` with `hc_capture_json`
- AND the command is `get quayregistry -A || true`

#### Scenario: 06_layered datasciencecluster
- GIVEN live collection runs `06_layered.sh`
- WHEN that category script finishes its capture list
- THEN it writes `06_layered/datasciencecluster.json` with `hc_capture_json`
- AND the command is `get datasciencecluster -A || true`


### Requirement: Live captures in 07_cluster_health.sh
`07_cluster_health.sh` SHALL run in category `07_cluster_health` and SHALL capture the check names in the scenarios.

#### Scenario: 07_cluster_health nodes
- GIVEN live collection runs `07_cluster_health.sh`
- WHEN that category script finishes its capture list
- THEN it writes `07_cluster_health/nodes.json` with `hc_capture_json`
- AND the command is `get nodes`

#### Scenario: 07_cluster_health node_conditions
- GIVEN live collection runs `07_cluster_health.sh`
- WHEN that category script finishes its capture list
- THEN it writes `07_cluster_health/node_conditions.json` with `hc_capture_json`
- AND the command is `get nodes`

#### Scenario: 07_cluster_health pods_all
- GIVEN live collection runs `07_cluster_health.sh`
- WHEN that category script finishes its capture list
- THEN it writes `07_cluster_health/pods_all.json` with `hc_capture_json`
- AND the command is `get pods -A`

#### Scenario: 07_cluster_health master_nodes
- GIVEN live collection runs `07_cluster_health.sh`
- WHEN that category script finishes its capture list
- THEN it writes `07_cluster_health/master_nodes.json` with `hc_capture_json`
- AND the command is `get nodes -l node-role.kubernetes.io/master`

#### Scenario: 07_cluster_health clusterversion
- GIVEN live collection runs `07_cluster_health.sh`
- WHEN that category script finishes its capture list
- THEN it writes `07_cluster_health/clusterversion.json` with `hc_capture_json`
- AND the command is `get clusterversion`

#### Scenario: 07_cluster_health clusteroperators
- GIVEN live collection runs `07_cluster_health.sh`
- WHEN that category script finishes its capture list
- THEN it writes `07_cluster_health/clusteroperators.json` with `hc_capture_json`
- AND the command is `get clusteroperator`

#### Scenario: 07_cluster_health firing_alerts
- GIVEN live collection runs `07_cluster_health.sh`
- WHEN that category script finishes its capture list
- THEN it writes `07_cluster_health/firing_alerts.json` with `hc_capture_text`
- AND the command is `oc -n openshift-monitoring exec              "$(oc get pods -n openshift-monitoring -l prometheus=k8s -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo '')"              -c prometheus --              curl -s http://localhost:9090/api/v1/alerts 2>/dev/null || true`

#### Scenario: 07_cluster_health events
- GIVEN live collection runs `07_cluster_health.sh`
- WHEN that category script finishes its capture list
- THEN it writes `07_cluster_health/events.json` with `hc_capture_json`
- AND the command is `get events -A || true`

#### Scenario: 07_cluster_health jobs
- GIVEN live collection runs `07_cluster_health.sh`
- WHEN that category script finishes its capture list
- THEN it writes `07_cluster_health/jobs.json` with `hc_capture_json`
- AND the command is `get jobs -A || true`


### Requirement: Live captures in 08_day2.sh
`08_day2.sh` SHALL run in category `08_day2` and SHALL capture the check names in the scenarios.

#### Scenario: 08_day2 resourcequota
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/resourcequota.json` with `hc_capture_json`
- AND the command is `get resourcequota -A`

#### Scenario: 08_day2 limitrange
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/limitrange.json` with `hc_capture_json`
- AND the command is `get limitrange -A`

#### Scenario: 08_day2 image_config
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/image_config.json` with `hc_capture_json`
- AND the command is `get image.config.openshift.io cluster`

#### Scenario: 08_day2 clusterversion
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/clusterversion.json` with `hc_capture_json`
- AND the command is `get clusterversion`

#### Scenario: 08_day2 top_nodes
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/top_nodes.json` with `hc_capture_text`
- AND the command is `oc adm top nodes`

#### Scenario: 08_day2 top_pods
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/top_pods.json` with `hc_capture_text`
- AND the command is `oc adm top pods -A --sort-by=memory`

#### Scenario: 08_day2 apiserver
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/apiserver.json` with `hc_capture_json`
- AND the command is `get apiserver cluster`

#### Scenario: 08_day2 proxy
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/proxy.json` with `hc_capture_json`
- AND the command is `get proxy cluster`

#### Scenario: 08_day2 namespaces
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/namespaces.json` with `hc_capture_json`
- AND the command is `get namespaces`

#### Scenario: 08_day2 subscriptions
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/subscriptions.json` with `hc_capture_json`
- AND the command is `get subscriptions -A`

#### Scenario: 08_day2 deploymentconfig
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/deploymentconfig.json` with `hc_capture_json`
- AND the command is `get dc -A || true`

#### Scenario: 08_day2 certificates
- GIVEN live collection runs `08_day2.sh`
- WHEN that category script finishes its capture list
- THEN it writes `08_day2/certificates.json` with `hc_capture_json`
- AND the command is `get certificates -A || true`


### Requirement: Live captures in 09_security.sh
`09_security.sh` SHALL run in category `09_security` and SHALL capture the check names in the scenarios.

#### Scenario: 09_security scc
- GIVEN live collection runs `09_security.sh`
- WHEN that category script finishes its capture list
- THEN it writes `09_security/scc.json` with `hc_capture_json`
- AND the command is `get scc`

#### Scenario: 09_security oauth
- GIVEN live collection runs `09_security.sh`
- WHEN that category script finishes its capture list
- THEN it writes `09_security/oauth.json` with `hc_capture_json`
- AND the command is `get oauth cluster`

#### Scenario: 09_security clusterrolebindings
- GIVEN live collection runs `09_security.sh`
- WHEN that category script finishes its capture list
- THEN it writes `09_security/clusterrolebindings.json` with `hc_capture_json`
- AND the command is `get clusterrolebinding`

#### Scenario: 09_security rolebindings
- GIVEN live collection runs `09_security.sh`
- WHEN that category script finishes its capture list
- THEN it writes `09_security/rolebindings.json` with `hc_capture_json`
- AND the command is `get rolebinding -A`

#### Scenario: 09_security compliance_scans
- GIVEN live collection runs `09_security.sh`
- WHEN that category script finishes its capture list
- THEN it writes `09_security/compliance_scans.json` with `hc_capture_json`
- AND the command is `get compliancescan -A`

#### Scenario: 09_security compliance_suites
- GIVEN live collection runs `09_security.sh`
- WHEN that category script finishes its capture list
- THEN it writes `09_security/compliance_suites.json` with `hc_capture_json`
- AND the command is `get compliancesuite -A`

#### Scenario: 09_security namespaces
- GIVEN live collection runs `09_security.sh`
- WHEN that category script finishes its capture list
- THEN it writes `09_security/namespaces.json` with `hc_capture_json`
- AND the command is `get namespaces`

#### Scenario: 09_security secrets_count
- GIVEN live collection runs `09_security.sh`
- WHEN that category script finishes its capture list
- THEN it writes `09_security/secrets_count.json` with `hc_capture_text`
- AND the command is `$HC_CLI get secrets -A --no-headers`

#### Scenario: 09_security clusterrolebindings_admin
- GIVEN live collection runs `09_security.sh`
- WHEN that category script finishes its capture list
- THEN it writes `09_security/clusterrolebindings_admin.json` with `hc_capture_json`
- AND the command is `get clusterrolebinding`


### Requirement: Live Prometheus and etcdctl captures
`10_metrics.sh` SHALL query Thanos through a monitoring pod and SHALL run `etcdctl` inside a running etcd pod. A missing querier or etcd pod SHALL write an error or skip envelope for that check and SHALL continue. These queries SHALL NOT run in supportshell.

#### Scenario: node_cpu_requests_pct
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/node_cpu_requests_pct.json`
- AND the series is kube_pod_container_resource_requests cpu divided by allocatable

#### Scenario: node_memory_requests_pct
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/node_memory_requests_pct.json`
- AND the series is memory requests divided by allocatable

#### Scenario: node_cpu_limits_pct
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/node_cpu_limits_pct.json`
- AND the series is cpu limits divided by allocatable

#### Scenario: node_memory_limits_pct
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/node_memory_limits_pct.json`
- AND the series is memory limits divided by allocatable

#### Scenario: etcd_disk_wal_fsync_p99
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/etcd_disk_wal_fsync_p99.json`
- AND the series is etcd WAL fsync P99

#### Scenario: etcd_disk_backend_p99
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/etcd_disk_backend_p99.json`
- AND the series is etcd backend commit P99

#### Scenario: etcd_leader_changes_1h
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/etcd_leader_changes_1h.json`
- AND the series is etcd leader changes over 1h

#### Scenario: etcd_db_size_bytes
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/etcd_db_size_bytes.json`
- AND the series is etcd db total size

#### Scenario: etcd_db_size_in_use
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/etcd_db_size_in_use.json`
- AND the series is etcd db size in use

#### Scenario: etcd_proposals_failed
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/etcd_proposals_failed.json`
- AND the series is etcd failed proposals over 1h

#### Scenario: etcd_heartbeat_failures
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/etcd_heartbeat_failures.json`
- AND the series is etcd heartbeat send failures over 1h

#### Scenario: apiserver_request_latency_p99
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/apiserver_request_latency_p99.json`
- AND the series is apiserver request duration P99

#### Scenario: apiserver_error_rate
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/apiserver_error_rate.json`
- AND the series is apiserver 5xx rate

#### Scenario: cert_expiry_days
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/cert_expiry_days.json`
- AND the series is apiserver client certificate expiry days

#### Scenario: node_memory_working_set_pct
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/node_memory_working_set_pct.json`
- AND the series is node working-set memory percent

#### Scenario: pvc_utilization_pct
- GIVEN a live cluster with a Thanos querier or etcd pod as required
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/pvc_utilization_pct.json`
- AND the series is kubelet volume used over capacity

#### Scenario: etcd endpoint health
- GIVEN a running etcd pod with its peer certificates
- WHEN `10_metrics.sh` runs
- THEN it writes `10_metrics/etcd_endpoint_health.json` from `etcdctl endpoint health --cluster -w json`
- AND it writes `10_metrics/etcd_endpoint_status.json` from `etcdctl endpoint status --cluster -w json`


### Requirement: Live hardware and CCX
`11_hardware.sh` SHALL `oc debug` each node and SHALL write `11_hardware/node_hw_<short>.json` including disk rotational data when the debug command succeeds. A debug or JSON parse failure SHALL write `_hc_error` for that node and SHALL continue. `12_ccx.sh` SHALL copy `HC_CCX_RULES_FILE` to `12_ccx/ccx_rules.json` when the variable is set, and SHALL write `_hc_not_found` when it is unset.

#### Scenario: Hardware file per node
- GIVEN `oc get nodes` returns two nodes and `oc debug` succeeds for both
- WHEN `11_hardware.sh` runs
- THEN two `node_hw_<short>.json` files exist under `11_hardware`

#### Scenario: CCX payload is optional
- GIVEN `HC_CCX_RULES_FILE` is unset
- WHEN `12_ccx.sh` runs
- THEN `12_ccx/ccx_rules.json` contains `_hc_not_found` true

