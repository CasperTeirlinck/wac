#!/usr/bin/env bash
# Act on the OUTER pane hosting a tab-session's client: when focus/resize hits
# a tab-session edge, continue into the outer layout.
#
#   stack-escape.sh move|resize U|D|L|R <client_tty>
#   stack-escape.sh surface <client_tty> <session>
#
# move/resize: the tty is the caller's #{client_tty} (expanded by the tmux
# binding or read from nvim's environment), so the lookup is pinned to the
# client that asked. The hosting pane is the one whose pane_tty equals that
# client tty.
#
# surface: called from the client-session-changed hook. A NESTED client (its
# tty IS some pane's tty) landing on a non-stack session mirrors an outer
# session inside its own pane; bounce it back to its home stack session.
# ponytail: home is derived from the hosting window's id, so an explicitly
# named session (`tmi foo`) that strays is replaced by the default-named one;
# track the name in a pane option if named stacks become common.
op="$1"
if [ "$op" = surface ]; then
  ctty="${2:-}" sess="${3:-}"
  panes="$(tmux list-panes -a -F '#{pane_tty} #{session_name}:#{window_index} #{pane_id} #{window_id}')"
  hostrow="$(printf '%s\n' "$panes" | awk -v t="$ctty" '$1==t{print; exit}')"
  if [ -n "$hostrow" ]; then
    # NESTED client (its tty is a pane's tty). It must only ever display a
    # stack session: anything else (e.g. a picker ran on the wrong client)
    # mirrors an outer session inside its own pane, and the abandoned stack
    # session gets reaped by destroy-unattached. Bounce it to its home
    # session, rebuilding the home first if it was already destroyed.
    case "$sess" in stack-*) exit 0 ;; esac
    read -r _ _ hostpane hostwid <<<"$hostrow"
    home="stack-${hostwid#@}"
    tmux has-session -t "=$home" 2>/dev/null \
      || TMUX_PANE="$hostpane" ~/.config/tmux/stack-session.sh --no-attach "${hostwid#@}"
    tmux switch-client -c "$ctty" -t "=$home"
    tmux set -t "=$home:" destroy-unattached on
    exit 0
  fi
  exit 0
fi

dir="$2" ctty="${3:-}"
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
