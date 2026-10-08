"""Public-contract tests for 7.1/7.2 aliases and CoreDNS alerts."""
from __future__ import annotations

from hc_report.evaluators.platform import _evaluate_coredns_alerts
from hc_report.kb_loader import load_kb


def _coredns_status(alerts_data: dict) -> str:
    checks = _evaluate_coredns_alerts(alerts_data, "7.1", "Base Platform Checks")
    assert checks, "7.1.dns.coredns_alerts not emitted"
    return checks[0].status


def test_coredns_alerts_fail_when_coredns_errors_high_firing() -> None:
    alerts_data = {
        "data": {
            "alerts": [
                {"state": "firing", "labels": {"alertname": "CoreDNSErrorsHigh"}},
            ],
        },
    }
    assert _coredns_status(alerts_data) == "FAIL"


def test_coredns_alerts_pass_when_no_coredns_alerts() -> None:
    alerts_data = {"data": {"alerts": []}}
    assert _coredns_status(alerts_data) == "PASS"


def test_master_memory_alias_targets_native() -> None:
    knowledge_base = load_kb()
    assert knowledge_base.cited_target("7.1.tsr.1_4_1_3_master_memory") == "7.1.nodes.master_mem"
    assert knowledge_base.cited_target("7.1.tsr.1_4_1_3_master_memory")


def test_auth_az_haproxy_aliases_target_natives() -> None:
    knowledge_base = load_kb()
    assert knowledge_base.cited_target("7.1.tsr.1_5_17_authentication") == "7.1.sys.auth"
    assert knowledge_base.cited_target("7.1.tsr.1_5_17_authentication")
    assert knowledge_base.cited_target("7.2.tsr.2_2_2_master_av_zone_labels") == "7.2.topo.master_az"
    assert knowledge_base.cited_target("7.2.tsr.2_2_2_master_av_zone_labels")
    assert knowledge_base.cited_target("7.2.tsr.2_2_3_haproxy_ha") == "7.2.topo.haproxy_ha"
    assert knowledge_base.cited_target("7.2.tsr.2_2_3_haproxy_ha")


def test_dns_tsr_and_coredns_ccx_alias_to_native() -> None:
    knowledge_base = load_kb()
    assert knowledge_base.cited_target("7.1.tsr.1_5_2_3_dns_alerts") == "7.1.dns.coredns_alerts"
    assert knowledge_base.cited_target("7.1.tsr.1_5_2_3_dns_alerts")
    assert knowledge_base.cited_target("7.7.ccx_internal.high_core_dns_errors_high_alerts") == "7.1.dns.coredns_alerts"
    assert knowledge_base.cited_target("7.7.ccx_internal.high_core_dns_errors_high_alerts")


def test_unrelated_alert_aliases_not_coredns() -> None:
    knowledge_base = load_kb()
    assert knowledge_base.cited_target("7.3.tsr.3_5_9_etcd_alerts") == "7.5.alerts.critical"
    assert knowledge_base.cited_target("7.3.tsr.3_5_9_etcd_alerts") != "7.1.dns.coredns_alerts"


def test_firewalls_tsr_aliases_overlay_not_sys_firewall() -> None:
    knowledge_base = load_kb()
    assert knowledge_base.cited_target("7.1.tsr.1_5_5_firewalls") == "7.1.net.overlay_ports"
    assert knowledge_base.cited_target("7.1.tsr.1_5_5_firewalls") != "7.1.sys.firewall"
    assert knowledge_base.cited_target("7.1.tsr.1_5_5_firewalls")
