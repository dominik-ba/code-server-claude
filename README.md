# code-server-claude

[![Build and Push Image](https://github.com/dominik-ba/code-server-claude/actions/workflows/build-image.yml/badge.svg)](https://github.com/dominik-ba/code-server-claude/actions/workflows/build-image.yml)

A [code-server](https://github.com/coder/code-server) image with the
[Claude Code CLI](https://github.com/anthropics/claude-code) preinstalled, for running
Claude Code as a browser-based coding agent.

## Overview

This repository builds a container image that combines the official `codercom/code-server`
image with Node.js 22 and the `@anthropic-ai/claude-code` npm package, so Claude Code can be
used directly from a code-server terminal.

## Image Contents

- Base image: `codercom/code-server` (configurable base image/tag via build arguments)
- Node.js 22.x (via NodeSource)
- `@anthropic-ai/claude-code` (pinned version, see `image/Dockerfile`)

## Build

To build the container image locally:

```bash
docker build -t code-server-claude ./image
```

To build with a custom base image or tag:

```bash
docker build \
  --build-arg CODE_SERVER_IMAGE=codercom/code-server \
  --build-arg CODE_SERVER_TAG=4.136.2-39 \
  -t code-server-claude ./image
```

## Image registry

The published image is available from GitHub Container Registry at:

```text
ghcr.io/dominik-ba/code-server-claude:latest
```

Pull the image directly from GHCR:

```bash
docker pull ghcr.io/dominik-ba/code-server-claude:latest
```

## Run

The image inherits code-server's default entrypoint and listens on port `8080`. At minimum,
set a `PASSWORD` for code-server itself and an `ANTHROPIC_API_KEY` for Claude Code:

```bash
docker run --rm -p 8080:8080 \
  -e PASSWORD=change-me \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -v "$PWD":/home/coder/project \
  ghcr.io/dominik-ba/code-server-claude:latest
```

Then open <http://localhost:8080>, open a terminal, and run `claude` to start Claude Code.

For Raspberry Pi / ARM64 devices, pull the ARM-compatible image explicitly:

```bash
docker pull --platform linux/arm64 ghcr.io/dominik-ba/code-server-claude:latest
```

## License

This project is licensed under the terms of the `LICENSE` file.
