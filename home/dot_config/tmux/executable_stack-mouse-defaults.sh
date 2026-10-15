#!/usr/bin/env bash
# Copy tmux's DEFAULT root-table bindings (all mouse: status-bar tab clicks,
# pane focus clicks, border drag-resize, wheel scrolling, right-click menus)
# into stack-root. Tab-sessions replace root with stack-root, and a custom
# table starts empty, so without this pass none of the default mouse handling
# works in them. Reading the defaults from a scratch server keeps this
# correct across tmux versions and avoids copying this setup's own root
# bindings.
set -u
tmp="$(mktemp)"
tmux -L stack-defaults -f /dev/null start-server \; list-keys -T root 2>/dev/null \
  | sed 's/-T root/-T stack-root/' > "$tmp"
tmux -L stack-defaults kill-server 2>/dev/null
[ -s "$tmp" ] && tmux source-file "$tmp"
rm -f "$tmp"
