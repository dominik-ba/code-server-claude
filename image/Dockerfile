ARG CODE_SERVER_IMAGE=codercom/code-server
ARG CODE_SERVER_TAG=4.136.2-39
FROM $CODE_SERVER_IMAGE:$CODE_SERVER_TAG

USER root

ARG NODE_MAJOR=22
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates git && \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g @anthropic-ai/claude-code@2.1.292 && \
    apt-get purge -y curl && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

USER coder
WORKDIR /home/coder/project

EXPOSE 8080
