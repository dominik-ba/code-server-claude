#!/bin/bash
# Run by code-server's entrypoint (all executables in $ENTRYPOINTD) before code-server
# starts. Opt-in: starts `claude remote-control` in a detached tmux session so the
# workspace can be driven from claude.ai/code or the Claude mobile app.

case "${CLAUDE_REMOTE_CONTROL:-}" in
    1 | true | yes) ;;
    *) exit 0 ;;
esac

session="${CLAUDE_REMOTE_CONTROL_TMUX_SESSION:-claude-rc}"
if tmux has-session -t "$session" 2>/dev/null; then
    exit 0
fi

# tmux daemonizes, so this returns immediately and code-server starts as usual.
if ! tmux new-session -d -s "$session" -x 200 -y 50 /usr/local/bin/claude-remote-control; then
    echo "claude-remote-control: could not start tmux session '$session'" >&2
fi
exit 0
