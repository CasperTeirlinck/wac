#!/usr/bin/env bash
# Records this Claude Code session's status for the tmux agent sidebar
# (~/.config/tmux/agent-sidebar.sh). Wired up as Claude Code hooks in
# ~/.claude/settings.json — the status is passed as $1:
#   UserPromptSubmit -> working    Notification -> wait    Stop -> done
#   PostToolUse      -> working  (clears a stale `wait` after an approval)
#
# Keyed by <socket>:<pane> so the sidebar can join it to a live pane across
# BOTH tmux servers in the nested (tmi) setup: the outer `default` socket and
# the inner `inner` socket. $TMUX / $TMUX_PANE are inherited from Claude Code
# (the pane it runs in), and $TMUX looks like "/tmp/tmux-501/inner,PID,SID",
# so its socket basename disambiguates which server the agent lives on.
status="${1:-working}"

[ -z "${TMUX:-}" ] && exit 0            # Claude not in tmux -> nothing to track

socket="$(basename "${TMUX%%,*}")"      # ".../inner,PID,SID" -> inner
dir="$HOME/.cache/tmux-agent-status"
mkdir -p "$dir"
printf '%s' "$status" > "$dir/${socket}:${TMUX_PANE}.status"
exit 0
