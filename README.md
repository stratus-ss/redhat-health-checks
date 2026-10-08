# Red Hat health checks

OpenShift health-check collection and the deterministic report engine.

Operator guide: [scripts/health_check/README.md](scripts/health_check/README.md).

```bash
make setup CLIENT="Example Client" PROJECT="HC"
make hc-collect KUBECONFIG=/path/to/kubeconfig
make hc-report
make test
```

`main` is the health-check snapshot. `livecheck_parity` is the later native-scoring snapshot. Collection runs on the host. Report, HTML, and PDF generation run in the container image.
