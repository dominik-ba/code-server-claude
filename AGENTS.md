# AGENTS.md

Tool-neutral guidance for AI coding agents (GitHub Copilot, Claude Code) working in
this repository. `CLAUDE.md` and `.github/copilot-instructions.md` reference this file;
keep repository facts here and avoid duplicating them elsewhere.

## What this repository is

Builds the container image `ghcr.io/dominik-ba/code-server-claude`: the official
`codercom/code-server` image (Debian variant) plus Node.js 22, the Claude Code CLI
(`@anthropic-ai/claude-code`) and `kubectl`. It runs as a browser-based coding workspace.
The repo is public; anyone can open pull requests from forks.

The main consumer is the `claude-agent` Helm chart in
[dominik-ba/my-raspi-cluster](https://github.com/dominik-ba/my-raspi-cluster)
(`gitops/helm/claude-agent`), deployed by ArgoCD on an arm64 k3s cluster (Kubernetes 1.33).
Deployment concerns (auth, storage, RBAC, ingress) belong in that chart, not in the image.

## Layout

- `image/Dockerfile`: the image. All versions are `ARG`s: `CODE_SERVER_TAG`,
  `NODE_MAJOR`, `CLAUDE_CODE_VERSION`, `KUBECTL_VERSION`.
- `.hadolint.yaml`: hadolint settings (apt version pinning ignored on purpose).
- `.github/workflows/ci.yml`: PR and main tests (hadolint, amd64 + arm64 build, amd64 smoke test).
- `.github/workflows/build-image.yml`: the only publisher (main and manual runs).
- `renovate.json`: updates for the base image, Claude Code CLI, kubectl and actions.

## Commands

| Purpose | Command |
| --- | --- |
| Build locally | `docker build -t code-server-claude ./image` |
| Build arm64 | `docker buildx build --platform linux/arm64 ./image` (slow under QEMU) |
| Lint | `docker run --rm -i hadolint/hadolint hadolint --config .hadolint.yaml - < image/Dockerfile` |
| Run | `docker run --rm -p 8080:8080 -e PASSWORD=change-me code-server-claude` |

## Validation expectations

Before proposing a change as complete, run and report what applies:

1. hadolint on `image/Dockerfile`.
2. A local amd64 build plus the checks from the CI smoke test (`code-server --version`,
   `node --version`, `claude --version`, `kubectl version --client`, `/healthz` returns 200,
   `/` redirects to the login). If Docker is not available locally, say so and rely on the
   PR's CI run.
3. arm64 is built in CI; changes that touch architecture-specific downloads must use
   `TARGETARCH`.

## Image tags and versions

- Published tags: `<year>.<month><day>.<run number>` (sortable, pinned by consumers, tracked
  by Renovate) and `cs<code-server>-claude<claude-code>` (informative). There is no `latest`.
- Use Debian-based code-server tags only (e.g. `4.141.1`). The `-39`/`-fedora` variants have
  no `apt-get`.
- `KUBECTL_VERSION` stays within the cluster's Kubernetes minor (`allowedVersions` in
  `renovate.json`); raise it together with the cluster upgrade.
- Every version change goes through `image/Dockerfile` so Renovate and the tag computation
  in `build-image.yml` see it.

## Conventions to preserve

- The image ends as user `coder` (uid 1000) with workdir `/home/coder/project`; the cluster
  relies on uid/gid 1000 for its SMB storage.
- Keep the code-server entrypoint and port 8080.
- Downloads are pinned and checksum-verified where the upstream publishes checksums.
- 2-space indentation for YAML/JSON, 4 spaces for shell (`.editorconfig`); English for code
  and docs.

## Security notes

- No secrets in the repository or the image. `PASSWORD` and `ANTHROPIC_API_KEY` are runtime
  environment variables.
- Fork PRs run CI with a read-only `GITHUB_TOKEN` and no secrets. Do not use
  `pull_request_target`, do not add `workflow_run` jobs that consume PR artifacts, and do
  not log in to a registry or push from PR jobs. Only `build-image.yml` on `main` has
  `packages: write`.
- Third-party actions are pinned to commit SHAs (Renovate keeps them current). Keep new
  actions pinned the same way.

## Scope limit for agents

Only change what the task asks. Do not change the publish workflow, its permissions or the
tag scheme as a side effect. When an industry best practice would materially improve the
image, explain the alternative and its trade-offs before applying it.
