# The runner image of Sustenaut's self-hosted CI (the scale set sustenaut-ci, which
# Sustenaut/shared-infra's help/ci-runners.md describes): GitHub's actions-runner image,
# pinned by digest, plus what pubkit's reusable workflows take for granted on GitHub's
# ubuntu-latest. The base already has git, curl, jq, unzip, sudo and the Docker CLI with
# buildx; the job's dockerd runs beside it in the pod.
#
# What a job installs for itself (setup-python, setup-node, rustup, Terraform, Playwright
# with --with-deps) it still installs: the runner may sudo apt-get, as on ubuntu-latest.
FROM ghcr.io/actions/actions-runner:2.338.2@sha256:759a1d94a15b05941aba5196974ff43fe15b4cbba29b694b35cbc32a1166b232

LABEL org.opencontainers.image.source="https://github.com/Sustenaut/ci-runner" \
      org.opencontainers.image.description="Sustenaut's self-hosted GitHub Actions runner: actions-runner plus the tools pubkit's CI expects of ubuntu-latest." \
      org.opencontainers.image.licenses="Apache-2.0"

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# GitHub CLI from its own apt repository, its key checked by fingerprint.
ARG GH_KEY_FINGERPRINT=2C6106201985B60E6C7AC87323F3D4EA75716059
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && gpg --show-keys --with-colons /usr/share/keyrings/githubcli-archive-keyring.gpg | grep -q "^fpr:::::::::${GH_KEY_FINGERPRINT}:" \
    && chmod 0644 /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
       build-essential make pkg-config libssl-dev \
       python3 python3-venv python3-pip python3-dev \
       shellcheck gh \
       zip xz-utils zstd wget rsync file gnupg ca-certificates tzdata locales \
    && rm -rf /var/lib/apt/lists/*

USER runner
