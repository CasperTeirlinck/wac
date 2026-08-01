#!/usr/bin/env bash
# One persistent, interactive sidebar listing the tree of ALL Claude Code
# agents across BOTH tmux servers in the nested (tmi) setup — the outer
# `default` socket and the inner `inner` socket. No plugin: tmux-agent-status
# plugins render into a single server and can't see the other socket's panes,
# which is exactly the view we need. Instead we read the socket-agnostic status
# files written by ~/.claude/tmux-agent-status.sh and join them to each
# server's live panes.
#
# Inside the sidebar pane: Up/Down (or j/k) move the cursor, Enter jumps focus
# to that agent's pane — across windows, panes, and the inner/outer boundary.
#
# Usage:
#   agent-sidebar.sh            interactive render loop (run inside the pane)
#   agent-sidebar.sh toggle     open/close the sidebar pane (from a tmux bind)
#   agent-sidebar.sh selfcheck  assert the status->glyph mapping
#
# ponytail: 1s poll via read -t (live refresh + responsive keys), no daemon.
# Upgrade to a fifo + `tmux wait-for` signalled from the hook only if laggy.

shopt -s extglob                        # for the pure-bash string ops in clean_name
DIR="$HOME/.cache/tmux-agent-status"
SOCKETS=(default inner)                 # outer, inner — hardcoded per this setup
WIDTH=30

# Glyphs close their colour with \033[39m (default fg) rather than \033[0m so a
# whole selected line can be wrapped in reverse-video (\033[7m…\033[0m) without
# an inner reset cancelling the highlight partway through.
glyph() {
  case "$1" in
    working) printf '\033[33m\xe2\x9a\xa1\033[39m' ;;   # U+26A1 lightning, yellow
    wait)    printf '\033[35m\xe2\x8f\xb8\033[39m' ;;   # U+23F8 pause, magenta
    done)    printf '\033[32m\xe2\x9c\x93\033[39m' ;;   # U+2713 check, green
    *)       printf '\033[90m\xe2\x97\x8b\033[39m' ;;   # U+25CB circle, grey (running, no status)
  esac
}

# Strip powerline "#[...]" style tokens (window names carry them), collapse
# whitespace, and truncate to the sidebar width.
clean_name() {
  # Pure bash (no sed/tr forks — this runs per row every refresh): strip
  # powerline "#[...]" style tokens, collapse whitespace, trim.
  local n="$1"
  n="${n//\#\[*([^]])]/}"                 # drop #[...] tokens
  n="${n//+([[:space:]])/ }"              # collapse whitespace runs to one space
  n="${n# }"; n="${n% }"                  # trim (single, since runs are collapsed)
  # Budget: 3-space indent + status glyph (assume 2 display cols, since
  # emoji-presentation glyphs like ⚡ are double-width) + 1 space + 1-col right
  # margin = 7. Truncate with a trailing … so a long name is cut off cleanly
  # instead of wrapping to the next line and mangling the indentation.
  local max=$((WIDTH - 7)); (( max < 1 )) && max=1
  [ "${#n}" -gt "$max" ] && n="${n:0:max-1}"$'\xe2\x80\xa6'
  printf '%s' "$n"
}

# Build ROW_TEXT[] (display lines, may hold \033 escapes) and the parallel
# ROW_TARGET[] (jump spec "socket|session|window|pane" for agent rows, empty
# for headers/separators). Also prunes status files whose pane is gone.
build() {
  ROW_TEXT=(); ROW_TARGET=()
  local w=0 t=0 d=0 live=() sock label had sess widx wname pid cmd key f st name
  local atext=() atgt=()
  for sock in "${SOCKETS[@]}"; do
    label=outer; [ "$sock" = inner ] && label=inner
    had=0
    while IFS=$'\t' read -r sess widx wname pid cmd; do
      [ "$cmd" = claude ] || continue           # only Claude Code panes
      key="${sock}:${pid}"; live+=("$key")
      f="$DIR/${key}.status"; st=running; [ -f "$f" ] && st="$(<"$f")"
      case "$st" in working) w=$((w+1));; wait) t=$((t+1));; done) d=$((d+1));; esac
      if [ "$had" = 0 ]; then atext+=(" \033[2m${label}\033[22m"); atgt+=(""); had=1; fi
      name="$(clean_name "$wname")"
      # Body only (glyph + name); render() prepends the cursor/indent marker.
      atext+=("$(glyph "$st") ${name}"); atgt+=("${sock}|${sess}|${widx}|${pid}")
    done < <(tmux -L "$sock" list-panes -a \
      -F $'#{session_name}\t#{window_index}\t#{window_name}\t#{pane_id}\t#{pane_current_command}' 2>/dev/null)
  done
  local kf kk
  for kf in "$DIR"/*.status; do
    [ -e "$kf" ] || continue
    kk="$(basename "$kf" .status)"
    printf '%s\n' "${live[@]}" | grep -qxF "$kk" || rm -f "$kf"
  done
  local head=" \033[1mAGENTS\033[22m  $(glyph working) $w  $(glyph wait) $t  $(glyph done) $d"
  local sep; sep=" \033[90m$(printf '%.0s\xe2\x94\x80' $(seq 1 $((WIDTH - 2))))\033[39m"
  ROW_TEXT+=("$head"); ROW_TARGET+=("")
  ROW_TEXT+=("$sep");  ROW_TARGET+=("")
  [ ${#atgt[@]} -eq 0 ] && { ROW_TEXT+=(" \033[2m no agents\033[22m"); ROW_TARGET+=(""); }
  local i
  for i in "${!atext[@]}"; do ROW_TEXT+=("${atext[i]}"); ROW_TARGET+=("${atgt[i]}"); done
}

# Draw the frame, highlighting the sel-th agent row; sets SEL_TARGET.
render() {
  AGENT_ROWS=(); local i
  for i in "${!ROW_TARGET[@]}"; do [ -n "${ROW_TARGET[i]}" ] && AGENT_ROWS+=("$i"); done
  local n=${#AGENT_ROWS[@]}
  (( sel < 0 )) && sel=0
  (( n > 0 && sel >= n )) && sel=$((n - 1))
  local selrow=-1
  if (( n > 0 )); then selrow=${AGENT_ROWS[sel]}; SEL_TARGET="${ROW_TARGET[selrow]}"; else SEL_TARGET=""; fi
  # Selection = a green ❯ cursor in column 1 + bold name (no background bar, so
  # the glyph keeps its own colour). Non-selected agent rows get a 1-col blank
  # marker so everything stays aligned; headers/separators print as-is.
  local out="\033[H\033[J"
  for i in "${!ROW_TEXT[@]}"; do
    if [ -z "${ROW_TARGET[i]}" ]; then
      out+="${ROW_TEXT[i]}\033[0m\n"
    elif [ "$i" = "$selrow" ]; then
      out+="\033[38;2;152;195;121m\xe2\x9d\xaf\033[39m \033[1m${ROW_TEXT[i]}\033[22m\033[0m\n"
    else
      out+="  ${ROW_TEXT[i]}\033[0m\n"
    fi
  done
  printf '%b' "$out"
}

# Jump focus to the pane named by "socket|session|window|pane".
jump() {
  local spec="$1"; [ -z "$spec" ] && return
  local sock sess win pane; IFS='|' read -r sock sess win pane <<<"$spec"
  if [ "$sock" = default ]; then
    tmux -L default select-window -t "$sess:$win" 2>/dev/null
    tmux -L default select-pane   -t "$pane"      2>/dev/null
    return
  fi
  # Inner pane: point the inner session at the target window+pane, then surface
  # the outer pane that's displaying that inner session's client. The inner
  # client's tty == the hosting outer pane's tty, so match on it.
  tmux -L inner select-window -t "$sess:$win" 2>/dev/null
  tmux -L inner select-pane   -t "$pane"      2>/dev/null
  local ctty otarget
  ctty="$(tmux -L inner list-clients -F '#{client_tty}|#{client_session}' 2>/dev/null \
    | awk -F'|' -v s="$sess" '$2==s{print $1; exit}')"
  [ -z "$ctty" ] && return                        # session not attached anywhere → can't surface
  otarget="$(tmux -L default list-panes -a -F '#{pane_tty}|#{session_name}:#{window_index}|#{pane_id}' 2>/dev/null \
    | awk -F'|' -v t="$ctty" '$1==t{print $2"|"$3; exit}')"
  [ -z "$otarget" ] && return
  tmux -L default select-window -t "${otarget%|*}" 2>/dev/null
  tmux -L default select-pane   -t "${otarget#*|}" 2>/dev/null
}

case "${1:-}" in
  toggle)
    existing="$(tmux show -gqv @agent_sidebar_pane)"
    if [ -n "$existing" ] && tmux list-panes -a -F '#{pane_id}' | grep -qxF "$existing"; then
      tmux kill-pane -t "$existing"
      tmux set -ug @agent_sidebar_pane
    else
      # -f: span the FULL window height (not just the focused pane, so it
      # doesn't land in one half of a split); -b: place it on the LEFT.
      pane="$(tmux split-window -hb -f -l "$WIDTH" -d -P -F '#{pane_id}' "exec '$0'")"
      tmux set -g @agent_sidebar_pane "$pane"
      tmux select-pane -t "$pane" -T AGENTS
    fi
    ;;
  jump)
    jump "$2" ;;                                   # agent-sidebar.sh jump "socket|sess|win|pane"
  selfcheck)
    [ "$(glyph working)" != "$(glyph done)" ] || { echo "FAIL: glyphs collide"; exit 1; }
    cn="$(clean_name '#[bold]ov-dp3-platform-sources2-mnv-base #[fg=green]claude#[fg=default]')"
    case "$cn" in *'#['*) echo "FAIL: style tokens survived: $cn"; exit 1 ;; esac
    [ "${#cn}" -le "$((WIDTH - 6))" ] || { echo "FAIL: name too wide, will wrap: $cn"; exit 1; }
    case "$cn" in *$'\xe2\x80\xa6') : ;; *) echo "FAIL: long name not ellipsized: $cn"; exit 1 ;; esac
    echo "OK ($cn)" ;;
  *)
    # Interactive loop. read -t 1 doubles as the ~1s live-refresh tick and the
    # key reader; arrows arrive as ESC [ A / ESC [ B.
    sel=0
    trap 'printf "\033[?25h"; exit 0' TERM INT     # restore cursor on exit
    trap ':' WINCH                                 # a resize interrupts read -> redraw now
    printf '\033[?25l'                             # hide cursor
    while true; do
      # Track the live pane width so truncation/separator react to a resize.
      # Ask tmux for this pane's width — tput cols returns the terminfo default
      # (~80 for screen/tmux TERM), not the real pane size.
      WIDTH=$(tmux display -p -t "$TMUX_PANE" '#{pane_width}' 2>/dev/null)
      [ -n "$WIDTH" ] && (( WIDTH >= 10 )) || WIDTH=30
      build; render
      # Handle keys with an INSTANT re-render (no rebuild — the tree data is
      # unchanged, only the cursor moves). Fall back to the outer loop to
      # rebuild after 1s idle or on a resize (read interrupted by WINCH).
      while read -rsn1 -t 1 key; do
        case "$key" in
          $'\e') read -rsn2 -t 0.05 rest
                 case "$rest" in '[A') ((sel--));; '[B') ((sel++));; esac ;;
          k) ((sel--)) ;;
          j) ((sel++)) ;;
          ''|$'\n'|$'\r') jump "$SEL_TARGET" ;;
        esac
        render
      done
    done ;;
esac
