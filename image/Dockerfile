# Debian-based code-server release (the "-39"/"-fedora" variants have no apt-get).
ARG CODE_SERVER_IMAGE=codercom/code-server
ARG CODE_SERVER_TAG=4.144.0
FROM $CODE_SERVER_IMAGE:$CODE_SERVER_TAG

USER 0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set by buildx per target platform (amd64, arm64).
ARG TARGETARCH

# The base image already ships curl, git and openssh-client.
# tmux hosts the optional Claude Remote Control server (see CLAUDE_REMOTE_CONTROL below).
# jq, unzip, zip, dnsutils (dig/nslookup) and netcat-openbsd (nc) are small helpers for
# JSON handling, archives and network debugging.
ARG NODE_MAJOR=22
ARG CLAUDE_CODE_VERSION=2.1.317
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates tmux jq unzip zip dnsutils netcat-openbsd && \
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" && \
    npm cache clean --force && \
    rm -rf /var/lib/apt/lists/*

# kubectl for cluster inspection; pinned to one Kubernetes minor (see allowedVersions in renovate.json).
ARG KUBECTL_VERSION=v1.33.13
RUN curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" && \
    echo "$(curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl.sha256")  /usr/local/bin/kubectl" | sha256sum -c - && \
    chmod 0755 /usr/local/bin/kubectl

# gh, yq and helm: pinned, checksum-verified static binaries (the Debian packages lag far behind).
ARG GH_VERSION=v2.103.3
ARG YQ_VERSION=v4.54.3
ARG HELM_VERSION=v4.3.1
RUN tmp="$(mktemp -d)" && cd "$tmp" && \
    gh_dir="gh_${GH_VERSION#v}_linux_${TARGETARCH}" && \
    curl -fsSLO "https://github.com/cli/cli/releases/download/${GH_VERSION}/${gh_dir}.tar.gz" && \
    curl -fsSL "https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION#v}_checksums.txt" | grep " ${gh_dir}.tar.gz\$" | sha256sum -c - && \
    tar -xzf "${gh_dir}.tar.gz" && \
    install -m 0755 "${gh_dir}/bin/gh" /usr/local/bin/gh && \
    curl -fsSLO "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH}.tar.gz" && \
    curl -fsSLO "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/checksums" && \
    curl -fsSLO "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/checksums_hashes_order" && \
    col="$(( $(grep -n '^SHA-256$' checksums_hashes_order | cut -d: -f1) + 1 ))" && \
    echo "$(awk -v f="yq_linux_${TARGETARCH}.tar.gz" -v c="$col" '$1 == f { print $c }' checksums)  yq_linux_${TARGETARCH}.tar.gz" | sha256sum -c - && \
    tar -xzf "yq_linux_${TARGETARCH}.tar.gz" "./yq_linux_${TARGETARCH}" && \
    install -m 0755 "yq_linux_${TARGETARCH}" /usr/local/bin/yq && \
    curl -fsSLO "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" && \
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz.sha256sum" | sha256sum -c - && \
    tar -xzf "helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" && \
    install -m 0755 "linux-${TARGETARCH}/helm" /usr/local/bin/helm && \
    cd / && rm -rf "$tmp"

# Optional Remote Control server, off by default. With CLAUDE_REMOTE_CONTROL=1 the startup
# hook runs `claude remote-control` in the tmux session "claude-rc" before code-server
# starts. The code-server base image runs every executable in $ENTRYPOINTD (/entrypoint.d).
COPY --chmod=0755 rootfs/entrypoint.d/ /entrypoint.d/
COPY --chmod=0755 rootfs/usr/local/bin/claude-remote-control /usr/local/bin/claude-remote-control
# New interactive shells print how to reach the Remote Control session when it runs.
COPY rootfs/usr/local/share/code-server-claude/ /usr/local/share/code-server-claude/
RUN for rc in /etc/bash.bashrc /etc/zsh/zshrc; do \
        printf '\n. /usr/local/share/code-server-claude/remote-control-hint.sh\n' >> "$rc"; \
    done

# uid 1000 is "coder" in the base image
USER 1000
# User-installed tools (pip --user, npm prefix, manual downloads) in ~/.local/bin are on PATH for
# every process, including non-interactive ones such as Claude sessions under Remote Control.
ENV PATH="/home/coder/.local/bin:${PATH}"
# Owned by coder so a volume mounted here (e.g. as CLAUDE_CONFIG_DIR) is writable.
RUN mkdir -p /home/coder/.claude
WORKDIR /home/coder/project

EXPOSE 8080
