#!/usr/bin/env bash
# Tab-session launcher (`tmi`): create-or-attach this workspace window's
# stack-* session and show it in the current pane as a nested client.
# The session lives on the SAME tmux server; its inner look and bindings come
# from session-scoped options (key tables in ~/.config/tmux/stack.conf), so
# the outer session keeps its global values.
set -euo pipefail

[ -n "${TMUX:-}" ] || { echo "stack-session: run inside tmux" >&2; exit 1; }

# Recursion guard: never nest a tab-session inside a tab-session. Resolved via
# the pane, not the client: this runs from a pane's shell, where $TMUX_PANE is
# authoritative and no client context exists.
case "$(tmux display -p -t "$TMUX_PANE" '#{session_name}')" in
  stack-*) echo "stack-session: already inside a tab-session" >&2; exit 1 ;;
esac

# Default name is tied to the hosting window, so each workspace window gets
# its own stable tab-session and re-running `tmi` there re-attaches (also
# after a resurrect restore).
name="stack-${1:-$(tmux display -p -t "$TMUX_PANE" '#{window_index}')}"

if ! tmux has-session -t "=$name" 2>/dev/null; then
  tmux new-session -d -s "$name" -c "$(tmux display -p '#{pane_current_path}')"
fi

# Trailing colon: set-option parses a bare "=name" as a window/pane target
# and errors; "=name:" pins it to the session.
t=("-t" "=$name:")
# Bindings live in stack-root/stack-prefix; prefix None means C-e is handled by
# an explicit switch-client -T in stack-root instead of tmux prefix processing.
tmux set "${t[@]}" prefix None
tmux set "${t[@]}" key-table stack-root

# --- Tab bar: top, no bg, tabs left, prefix dot right -------------------------
# Session-scoped copies of the styling the old inner server set globally.
# Window options (window-status-*, automatic-rename-format, mode-style) are
# NOT set here: they're identical to the outer globals in ~/.tmux.conf.
tmux set "${t[@]}" status-position top
tmux set "${t[@]}" status-interval 5
tmux set "${t[@]}" status-justify left
tmux set "${t[@]}" status-style bg=default
# Same active-window-index tracking as outer: the session-scoped hook in
# ~/.tmux.conf keeps it current per session; seed it here.
tmux set "${t[@]}" @active_window_index 1
# Session-name trailing cap: attribute-level conditionals, see ~/.tmux.conf
# for why whole-style ternaries are avoided.
tmux set "${t[@]}" status-left '#[fg=#21252b,bg=#98c379] #S #[fg=#98c379,bg=#{?#{==:#{@active_window_index},1},#3b3f4c,default},nobold,noitalics,nounderscore]#[default]'
tmux set "${t[@]}" status-left-length 60
# With prefix None, client_prefix never fires: the stack-prefix key table
# being active is the equivalent signal.
tmux set "${t[@]}" status-right '#[fg=colour240]C-e #[default]#{?#{==:#{client_key_table},stack-prefix},#[fg=red]●#[default],#[fg=colour240]●#[default]} '
tmux set "${t[@]}" status-right-length 40

# Attach as a nested client on the SAME server ($TMUX names the socket; the
# variable itself must be unset or tmux refuses to nest). destroy-unattached
# is chained AFTER the attach: setting it on a still-clientless session makes
# tmux destroy the session immediately. Once armed, closing the hosting pane
# (or `C-e d`) destroys the tab-session.
sock="${TMUX%%,*}"
exec env -u TMUX tmux -S "$sock" attach -t "=$name" \; set -t "=$name:" destroy-unattached on
