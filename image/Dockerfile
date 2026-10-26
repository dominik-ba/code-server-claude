# Debian-based code-server release (the "-39"/"-fedora" variants have no apt-get).
ARG CODE_SERVER_IMAGE=codercom/code-server
ARG CODE_SERVER_TAG=4.141.1
FROM $CODE_SERVER_IMAGE:$CODE_SERVER_TAG

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set by buildx per target platform (amd64, arm64).
ARG TARGETARCH

# The base image already ships curl, git and openssh-client.
ARG NODE_MAJOR=22
ARG CLAUDE_CODE_VERSION=2.1.266
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" && \
    npm cache clean --force && \
    rm -rf /var/lib/apt/lists/*

# kubectl for read-only cluster inspection; keep within one minor of the cluster's k3s version.
ARG KUBECTL_VERSION=v1.33.13
RUN curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" && \
    echo "$(curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl.sha256")  /usr/local/bin/kubectl" | sha256sum -c - && \
    chmod 0755 /usr/local/bin/kubectl

USER coder
WORKDIR /home/coder/project

EXPOSE 8080
