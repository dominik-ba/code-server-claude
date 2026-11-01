#!/bin/bash
# Prints the body of the GitHub release for an image version: the versions in the image
# and what changed since the previous release. Renovate shows this body in the update PRs
# of repositories that deploy the image.
#
# Usage: release-notes.sh <version> [<ref>]   (run from the repository root)
set -euo pipefail

version="$1"
ref="${2:-HEAD}"
image="ghcr.io/${GITHUB_REPOSITORY:-dominik-ba/code-server-claude}"

# Previous release tag (tags look like 2026.1026.12), skipping the one being created.
previous=$(git tag --list '[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | grep -vxF "$version" | head -n 1 || true)

arg() { git show "$1:image/Dockerfile" | sed -nE "s/^ARG $2=(.+)$/\1/p"; }

# component | Dockerfile ARG | release notes URL with {v} for the version
components=(
    "code-server|CODE_SERVER_TAG|https://github.com/coder/code-server/releases/tag/v{v}"
    "Claude Code|CLAUDE_CODE_VERSION|https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md"
    "Node.js|NODE_MAJOR|https://nodejs.org/en/blog/release"
    "kubectl|KUBECTL_VERSION|https://github.com/kubernetes/kubernetes/releases/tag/{v}"
)

echo "## Image contents"
echo
echo "| Component | Version | Change |"
echo "|---|---|---|"
for c in "${components[@]}"; do
    IFS='|' read -r name key url <<<"$c"
    new=$(arg "$ref" "$key")
    old=""
    if [ -n "$previous" ]; then
        old=$(arg "$previous" "$key")
    fi
    if [ -z "$previous" ] || [ "$old" = "$new" ]; then
        change="unchanged"
        [ -z "$previous" ] && change="-"
        echo "| $name | $new | $change |"
    else
        echo "| $name | **$new** | ${old:-none} → $new ([release notes](${url//\{v\}/$new})) |"
    fi
done
echo

if [ -n "$previous" ]; then
    echo "## Commits since $previous"
    echo
    git log --no-merges --format='- %s (%h)' "$previous..$ref"
    echo
fi

echo '```'
echo "docker pull $image:$version"
echo '```'
