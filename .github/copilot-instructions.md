# GitHub Copilot instructions

Primary guidance for AI agents is in **`AGENTS.md`** at the repository root; read it for
the layout, commands, tag scheme, conventions and security notes. This file is a short
standalone summary for Copilot Chat, agent mode and Copilot CLI.

## Repository

Builds `ghcr.io/dominik-ba/code-server-claude`: `codercom/code-server` (Debian) + Node.js
22 + Claude Code CLI + kubectl, multi-arch (amd64, arm64).

## Rules

- All versions are `ARG`s in `image/Dockerfile`; Renovate updates them. Debian-based
  code-server tags only (no `-39`/`-fedora`). kubectl stays on one Kubernetes minor (1.33).
- Tags are `<year>.<month><day>.<run>` and `cs<code-server>-claude<cli>`; no `latest`.
- The image ends as user `coder` (uid 1000), port 8080, code-server entrypoint.
- No secrets in the repo or image. Fork PRs run without secrets and with a read-only token:
  no `pull_request_target`, no registry login or push in PR jobs, actions pinned to commit
  SHAs. Only `build-image.yml` on `main` publishes.
- `.editorconfig`, English for code and docs.
