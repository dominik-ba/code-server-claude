# Debian-based code-server release (the "-39"/"-fedora" variants have no apt-get).
ARG CODE_SERVER_IMAGE=codercom/code-server
ARG CODE_SERVER_TAG=4.141.1
FROM $CODE_SERVER_IMAGE:$CODE_SERVER_TAG

USER 0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set by buildx per target platform (amd64, arm64).
ARG TARGETARCH

# The base image already ships curl, git and openssh-client.
# tmux hosts the optional Claude Remote Control server (see CLAUDE_REMOTE_CONTROL below).
ARG NODE_MAJOR=22
ARG CLAUDE_CODE_VERSION=2.1.312
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates tmux && \
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

# Optional Remote Control server, off by default. With CLAUDE_REMOTE_CONTROL=1 the startup
# hook runs `claude remote-control` in the tmux session "claude-rc" before code-server
# starts. The code-server base image runs every executable in $ENTRYPOINTD (/entrypoint.d).
COPY --chmod=0755 rootfs/entrypoint.d/ /entrypoint.d/
COPY --chmod=0755 rootfs/usr/local/bin/claude-remote-control /usr/local/bin/claude-remote-control

# uid 1000 is "coder" in the base image
USER 1000
# Owned by coder so a volume mounted here (e.g. as CLAUDE_CONFIG_DIR) is writable.
RUN mkdir -p /home/coder/.claude
WORKDIR /home/coder/project

EXPOSE 8080
