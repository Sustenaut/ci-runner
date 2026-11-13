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
       lsof iproute2 procps psmisc netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Node.js, as ubuntu-latest has it on the PATH: some jobs call node or npm without
# setup-node (a service's tests running `node --test`). The release tarball is checked
# against nodejs.org's SHA-256; the version follows pubkit's node-version default.
ARG NODE_VERSION=22.23.5
ARG NODE_SHA256_X64=cdeb8670a0c81f51b4dc4ac61919f9b1ad917b304bf8221eb939570663d240f8
ARG NODE_SHA256_ARM64=2babb9eb5264860d540849f4b064a6fbdebcdc323657d9d382ce23d313fd5e09
RUN case "$(dpkg --print-architecture)" in \
      amd64) arch=x64; sum="$NODE_SHA256_X64" ;; \
      arm64) arch=arm64; sum="$NODE_SHA256_ARM64" ;; \
      *) echo "no Node.js build for $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${arch}.tar.xz" -o /tmp/node.tar.xz \
    && echo "${sum}  /tmp/node.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
    && rm /tmp/node.tar.xz \
    && node --version && npm --version

USER runner
