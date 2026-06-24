# Hermes sandbox image — extends the default terminal backend image with extra CLIs.
# Build:   docker build -t hermes-sandbox:latest ~/Projects/hermes-sandbox/
# Wire up: in ~/.hermes/config.yaml set  terminal.docker_image: hermes-sandbox:latest
#          then  systemctl --user restart hermes-gateway
#
# Modular by convention: each tool is its own labeled block. To add a tool,
# append a new "# --- <tool> ---" RUN section below and rebuild. Keeping one
# RUN per tool keeps Docker layer caching effective (unchanged tools aren't
# rebuilt).

FROM nikolaik/python-nodejs:python3.11-nodejs20

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Shared prerequisites for the install steps below.
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates gnupg tar \
 && rm -rf /var/lib/apt/lists/*

# --- gh (GitHub CLI) — official apt repository -------------------------------
RUN install -d -m 0755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && chmod 0644 /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/* \
 && gh --version

# --- glab (GitLab CLI) — official release tarball ----------------------------
# Bump GLAB_VERSION to upgrade; releases: https://gitlab.com/gitlab-org/cli/-/releases
#ARG GLAB_VERSION=1.71.0
#RUN set -euo pipefail; \
#    arch="$(dpkg --print-architecture)"; \
#    case "$arch" in amd64) ga=amd64 ;; arm64) ga=arm64 ;; *) echo "unsupported arch $arch" >&2; exit 1 ;; esac; \
#    curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_${ga}.tar.gz" -o /tmp/glab.tgz; \
#    tar -xzf /tmp/glab.tgz -C /usr/local/bin --strip-components=1 bin/glab; \
#    rm -f /tmp/glab.tgz; \
#    glab --version
#
# --- next tool: add a new "# --- <tool> ---" block here and rebuild ----------

USER pn
