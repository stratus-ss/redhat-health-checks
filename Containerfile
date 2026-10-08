# Red Hat health checks — report image
#
# Contains pandoc, weasyprint, stitchmd, and the Python packages the
# report, HTML, and PDF targets need.
#
# Build: podman build -t redhat-health-checks .
# Run:   podman run --rm -v .:/workspace:Z redhat-health-checks <command>

FROM registry.fedoraproject.org/fedora:43 AS base

RUN dnf install -y --setopt=install_weak_deps=False \
        python3 python3-pip \
        pandoc \
        golang \
        curl \
        cairo pango gdk-pixbuf2 \
        libffi-devel \
        findutils which \
    && dnf clean all

RUN pip3 install --no-cache-dir weasyprint==66.0 pyyaml==6.0.3 tomli>=2.0 curl_cffi cursor-sdk==1.0.28

ENV GOPATH=/usr/local/go
RUN go install go.abhg.dev/stitchmd@v0.9.0 \
    && ln -s /usr/local/go/bin/stitchmd /usr/local/bin/stitchmd \
    && rm -rf /root/go /usr/local/go/pkg /usr/local/go/src

COPY templates/Health_Check/ /toolkit/templates/Health_Check/
COPY scripts/shared/ /toolkit/shared/
COPY scripts/health_check/ /toolkit/health_check/
COPY scripts/entrypoint.sh /toolkit/entrypoint.sh
COPY scripts/setup_project.py scripts/setup_status.py /toolkit/
RUN chmod +x /toolkit/entrypoint.sh

ARG SCRIPTS_HASH=unknown
LABEL org.opencontainers.image.scripts-hash=$SCRIPTS_HASH
LABEL org.opencontainers.image.title="redhat-health-checks" \
      org.opencontainers.image.description="OpenShift health-check collection and report engine" \
      org.opencontainers.image.licenses="GPL-3.0-only"

WORKDIR /workspace
ENTRYPOINT ["/toolkit/entrypoint.sh"]
CMD ["help"]
