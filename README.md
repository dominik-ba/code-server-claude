# code-server-claude

[![CI](https://github.com/dominik-ba/code-server-claude/actions/workflows/ci.yml/badge.svg)](https://github.com/dominik-ba/code-server-claude/actions/workflows/ci.yml)
[![Build and Push Image](https://github.com/dominik-ba/code-server-claude/actions/workflows/build-image.yml/badge.svg)](https://github.com/dominik-ba/code-server-claude/actions/workflows/build-image.yml)

A [code-server](https://github.com/coder/code-server) image with the
[Claude Code CLI](https://github.com/anthropics/claude-code) preinstalled, for running
Claude Code as a browser-based coding agent.

## Overview

This repository builds a container image that combines the official `codercom/code-server`
image with Node.js 22, the `@anthropic-ai/claude-code` npm package and `kubectl`, so Claude
Code can be used directly from a code-server terminal.

## Image Contents

- Base image: `codercom/code-server` (Debian variant; configurable base image/tag via build
  arguments). The base already includes git, curl and openssh-client.
- Node.js 22.x (via NodeSource)
- `@anthropic-ai/claude-code` (pinned via `ARG CLAUDE_CODE_VERSION`)
- `kubectl` (pinned via `ARG KUBECTL_VERSION`, checksum-verified, kept on one
  Kubernetes minor version, currently 1.33)

All versions are pinned in `image/Dockerfile` and updated by Renovate.

## Build

To build the container image locally:

```bash
docker build -t code-server-claude ./image
```

To build with a custom base image or tag:

```bash
docker build \
  --build-arg CODE_SERVER_IMAGE=codercom/code-server \
  --build-arg CODE_SERVER_TAG=4.141.1 \
  -t code-server-claude ./image
```

Use the Debian-based tags (`4.141.1`, `4.141.1-debian`, ...). The `-39`/`-fedora` variants
have no `apt-get` and the build fails on them.

## Image registry

Images are published to `ghcr.io/dominik-ba/code-server-claude` (amd64 and arm64) on every
change to `image/` on `main`, with two tags:

| Tag | Example | Purpose |
|---|---|---|
| `<year>.<month><day>.<run>` | `2026.1026.12` | Sortable version; pin this in deployments, Renovate tracks it |
| `cs<code-server>-claude<claude-code>` | `cs4.141.1-claude2.1.266` | Shows what the image contains |

There is no `latest` tag. The image labels `io.github.dominik-ba.code-server.version`,
`io.github.dominik-ba.claude-code.version` and `io.github.dominik-ba.kubectl.version`
record the exact contents.

```bash
docker pull ghcr.io/dominik-ba/code-server-claude:<tag>
```

## Run

The image inherits code-server's default entrypoint and listens on port `8080`. Set a
`PASSWORD` for code-server itself. For Claude Code, either set `ANTHROPIC_API_KEY` or run
`claude` in the terminal and log in with your Claude subscription (the login is stored in
`~/.claude`, or in `CLAUDE_CONFIG_DIR` if set, so keep that directory on a volume):

```bash
docker run --rm -p 8080:8080 \
  -e PASSWORD=change-me \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -v "$PWD":/home/coder/project \
  ghcr.io/dominik-ba/code-server-claude:<tag>
```

Then open <http://localhost:8080>, open a terminal, and run `claude` to start Claude Code.

The image is multi-arch; Raspberry Pi / ARM64 hosts pull the arm64 variant automatically.

## CI and pull requests

| Workflow | Trigger | Purpose |
|---|---|---|
| [CI](.github/workflows/ci.yml) | PRs and pushes to `main` | hadolint, build for amd64 + arm64, smoke test (tool versions, code-server `/healthz`, login required) |
| [Build and Push Image](.github/workflows/build-image.yml) | Changes to `image/` on `main`, manual | Build and push the multi-arch image to GHCR |

PRs from forks run CI with a read-only token and without secrets; nothing is published from
a PR. Workflows from first-time and outside contributors need approval before they run.

## License

This project is licensed under the terms of the `LICENSE` file.
