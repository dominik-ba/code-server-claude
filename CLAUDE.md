# CLAUDE.md

Read **`AGENTS.md`** in the repository root first. It holds the repository purpose,
layout, commands, tag scheme, conventions and security notes. This file only adds
Claude Code operating rules and does not repeat that content.

## Operating rules for this repository

- Before reporting a change as done, run the checks in "Validation expectations" in
  `AGENTS.md` and report the actual output. If Docker is not available, say so instead of
  claiming the image builds.
- Call out changes that affect deployments: the user (uid 1000), the entrypoint, port 8080,
  arm64 support or the bundled tools (`claude`, `kubectl`, `ssh`, `git`).
- Do not weaken workflow permissions or switch CI to `pull_request_target`; fork PRs
  must stay without secrets and write access.
- No secrets belong in this repository or the image.
