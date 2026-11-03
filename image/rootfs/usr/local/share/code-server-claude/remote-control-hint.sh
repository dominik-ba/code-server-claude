# Sourced by /etc/bash.bashrc and /etc/zsh/zshrc. When the Remote Control server from
# /entrypoint.d/50-claude-remote-control.sh is running, new interactive shells print how to
# reach it. Set CLAUDE_REMOTE_CONTROL_HINT=0 to turn this off.

_claude_rc_hint() {
    local session
    case "$-" in *i*) ;; *) return 0 ;; esac
    # Shells inside tmux (e.g. after attaching) do not need the hint.
    [ -z "${TMUX:-}" ] || return 0
    [ "${CLAUDE_REMOTE_CONTROL_HINT:-1}" != 0 ] || return 0
    command -v tmux >/dev/null 2>&1 || return 0
    session="${CLAUDE_REMOTE_CONTROL_TMUX_SESSION:-claude-rc}"
    tmux has-session -t "$session" 2>/dev/null || return 0

    echo "Claude Remote Control is running in tmux session '$session'."
    echo "  Open it:  tmux attach -t $session   (detach again with Ctrl-b d)"
    echo "  Connect:  Claude app or claude.ai/code, session named after" \
        "'${CLAUDE_REMOTE_CONTROL_SESSION_NAME_PREFIX:-$(uname -n)}'"
    if tmux capture-pane -p -S -50 -t "$session" 2>/dev/null |
        grep -qE 'must be logged in|requires a claude.ai subscription|only available with claude.ai'; then
        echo "  Not signed in yet: run 'claude auth login' (claude.ai subscription)."
    fi
    echo
}
_claude_rc_hint
unset -f _claude_rc_hint
