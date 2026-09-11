#!/usr/bin/env bash
# Act on the OUTER pane hosting a tab-session's client: when focus/resize hits
# a tab-session edge, continue into the outer layout.
#
#   stack-escape.sh move|resize U|D|L|R <client_tty>
#
# The tty is the caller's #{client_tty} (expanded by the tmux binding or read
# from nvim's environment), so the lookup is pinned to the client that asked.
# The hosting pane is the one whose pane_tty equals that client tty.
op="$1" dir="$2" ctty="${3:-}"
[ -n "$ctty" ] || exit 0

host="$(tmux list-panes -a -F '#{pane_tty} #{session_name}:#{window_index} #{pane_id}' \
  | awk -v t="$ctty" '$1==t {print $2" "$3; exit}')"
[ -n "$host" ] || exit 0            # client not hosted in a pane -> no-op
read -r win pane <<<"$host"

case "$op" in
  move)
    tmux select-window -t "$win"
    # No pane in that direction (hosting pane at the window edge) -> no-op.
    tmux select-pane "-$dir" -t "$pane" 2>/dev/null || :
    ;;
  resize)
    tmux resize-pane "-$dir" -t "$pane" 5
    ;;
esac
