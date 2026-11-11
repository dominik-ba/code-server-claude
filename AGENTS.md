# AGENTS.md

Tool-neutral guidance for AI coding agents (GitHub Copilot, Claude Code) working in
this repository. `CLAUDE.md` and `.github/copilot-instructions.md` reference this file;
keep repository facts here and avoid duplicating them elsewhere.

## What this repository is

Builds the container image `ghcr.io/dominik-ba/code-server-claude`: the official
`codercom/code-server` image (Debian variant) plus Node.js 22, the Claude Code CLI
(`@anthropic-ai/claude-code`), `kubectl` and helper tools (`gh`, `yq`, `helm`, `jq`). It runs as a browser-based coding workspace.
The repo is public; anyone can open pull requests from forks.

The image is meant to run in Kubernetes, including arm64 nodes. Deployment concerns (auth,
storage, RBAC, ingress) belong in the deploying Helm chart or manifests, not in the image.

## Layout

- `image/Dockerfile`: the image. All versions are `ARG`s: `CODE_SERVER_TAG`,
  `NODE_MAJOR`, `CLAUDE_CODE_VERSION`, `KUBECTL_VERSION`, `GH_VERSION`, `YQ_VERSION`,
  `HELM_VERSION`.
- `image/rootfs/`: files copied into the image. `entrypoint.d/50-claude-remote-control.sh`
  is run by code-server's entrypoint (`$ENTRYPOINTD` is `/entrypoint.d`) and, with
  `CLAUDE_REMOTE_CONTROL=1`, starts `usr/local/bin/claude-remote-control` (a restart loop
  around `claude remote-control`) in the tmux session `claude-rc`.
  `usr/local/share/code-server-claude/remote-control-hint.sh` is sourced from
  `/etc/bash.bashrc` and `/etc/zsh/zshrc` and tells new interactive shells how to attach.
- `.hadolint.yaml`: hadolint settings (apt version pinning ignored on purpose).
- `.github/workflows/ci.yml`: PR and main tests (hadolint, amd64 + arm64 build, amd64 smoke test).
- `.github/workflows/build-image.yml`: the only publisher (main and manual runs). After the
  push, its `release` job creates a GitHub release tagged with the image version, with notes
  from `.github/scripts/release-notes.sh`; Renovate shows them in deploying repositories.
- `renovate.json`: updates for the base image, Claude Code CLI, kubectl, gh, yq, helm and actions.

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
- `KUBECTL_VERSION` stays on one Kubernetes minor (currently 1.33, `allowedVersions` in
  `renovate.json`); raising the minor is a deliberate change.
- `HELM_VERSION` stays on helm 4.2.x (supports Kubernetes 1.33-1.36; `allowedVersions` in
  `renovate.json`); raise it together with `KUBECTL_VERSION`.
- Every version change goes through `image/Dockerfile` so Renovate and the tag computation
  in `build-image.yml` see it.

## Conventions to preserve

- The image ends as user `coder` (uid 1000) with workdir `/home/coder/project`; deployments
  rely on uid/gid 1000 (e.g. for volume ownership and `fsGroup`).
- Keep the code-server entrypoint and port 8080. Startup work goes into `/entrypoint.d`
  hooks, which must return quickly (they run before code-server starts).
- Optional features stay opt-in via environment variables; the default container only runs
  code-server.
- Downloads are pinned and checksum-verified where the upstream publishes checksums.
- 2-space indentation for YAML/JSON, 4 spaces for shell (`.editorconfig`); English for code
  and docs.

## Commit messages and PR titles

Release notes are generated, not written: `.github/scripts/release-notes.sh` lists the
subject line of every non-merge commit since the previous release, and Renovate copies the
notes into the update PRs of deploying repositories. The subject line is therefore the
changelog entry for people running the image.

- Write the subject as what changes for someone running the image, in the imperative, at
  most ~72 characters: `Add opt-in Claude Remote Control server at container start`, not
  `fix stuff`, `wip` or `address review`.
- Squash-merge PRs so the PR title becomes the one line in the notes; give the PR title the
  same care. With a merge commit, every commit subject of the branch shows up instead.
- Conventional prefixes are fine (`feat:`, `fix:`, `chore(deps):`, as Renovate uses), but
  the rest of the line must still say what changed.
- Commit bodies and PR descriptions do not appear in the notes; put the why there.
- Never edit the notes by hand or create release tags manually; the publish workflow owns
  both.

## Security notes

- No secrets in the repository or the image. `PASSWORD` and `ANTHROPIC_API_KEY` are runtime
  environment variables.
- Fork PRs run CI with a read-only `GITHUB_TOKEN` and no secrets. Do not use
  `pull_request_target`, do not add `workflow_run` jobs that consume PR artifacts, and do
  not log in to a registry or push from PR jobs. Only `build-image.yml` on `main` has
  `packages: write` (build job) and `contents: write` (release job, for tags and releases).
- Third-party actions are pinned to commit SHAs (Renovate keeps them current). Keep new
  actions pinned the same way.

## Pitfalls

- **Verify published artifacts without local registry logins.** Helm and Docker fall back to
  a Docker credential store (`credsStore` in `~/.docker/config.json`, e.g. Docker Desktop).
  A stale GHCR login there makes public packages fail with `403 denied`, and
  `--registry-config /dev/null` does not stop Helm from using it. Use an empty
  `DOCKER_CONFIG` directory plus an empty `--registry-config` file, or the anonymous token
  flow: `curl "https://ghcr.io/token?scope=repository:<owner>/<name>:pull&service=ghcr.io"`,
  then `GET https://ghcr.io/v2/<owner>/<name>/tags/list` with the bearer token.
- GHCR package visibility is a separate setting from repository visibility.
- `gh pr edit` can fail with "Projects (classic) is being deprecated". Use
  `gh api -X PATCH repos/<owner>/<repo>/pulls/<n> -f title=... -F body=@file.md`.
- This repository is public: never reference private consumer repositories (names, paths,
  hostnames, cluster details) in docs, AI files, comments, commit messages or PR texts.
- To check a published image without Docker: anonymous token flow (above), then fetch the
  manifest index (`Accept: application/vnd.oci.image.index.v1+json`) and confirm both
  `linux/amd64` and `linux/arm64` entries.

## Scope limit for agents

Only change what the task asks. Do not change the publish workflow, its permissions or the
tag scheme as a side effect. When an industry best practice would materially improve the
image, explain the alternative and its trade-offs before applying it.
