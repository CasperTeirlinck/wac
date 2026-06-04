#!/usr/bin/env bash
# Claude Code status line — mirrors Powerlevel10k lean layout
# Line 1: dir · git branch/status · model · permission mode · session duration
# Line 2: context bar · token count · ctx% · [5h pct (reset in) · 7d pct (reset in)]

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
perm_mode=$(echo "$input" | jq -r '.permission_mode // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')

# Shorten home directory to ~
# Note: quote the tilde — bash tilde-expands an unquoted ~ in the replacement
# back to $HOME, which would turn the substitution into a no-op.
home="$HOME"
short_dir="${cwd/#$home/'~'}"

# ANSI color helpers (real ESC chars so %s prints them correctly)
ESC=$'\033'
BLUE="${ESC}[34m"
YELLOW="${ESC}[33m"
GREEN="${ESC}[32m"
RED="${ESC}[31m"
CYAN="${ESC}[36m"
MAGENTA="${ESC}[35m"
GREY="${ESC}[90m"
HIGHLIGHT="${ESC}[1;96m"   # bold bright cyan  — fresh (post-compaction) context
COMPACTED="${ESC}[36m"     # dim cyan — carried-over compaction summary
FIVE_HR="${ESC}[1;92m"     # bold bright green — 5h subscription window
SEVEN_DAY="${ESC}[1;95m"   # bold bright magenta — 7d subscription window
BOLD_RED="${ESC}[1;91m"
RESET="${ESC}[0m"

# Format a number of seconds as "1d3h" / "2h15m" / "45m" / "30s"
fmt_duration() {
  awk -v s="$1" 'BEGIN {
    s = int(s + 0.5);
    if (s < 0) s = 0;
    d = int(s/86400); s -= d*86400;
    h = int(s/3600);  s -= h*3600;
    m = int(s/60);    s -= m*60;
    if (d > 0)      printf "%dd%dh", d, h;
    else if (h > 0) printf "%dh%dm", h, m;
    else if (m > 0) printf "%dm", m;
    else            printf "%ds", s;
  }'
}

# Convert a reset timestamp to "time until reset".
# Accepts either a Unix epoch number (per Claude Code's statusline schema) or
# an ISO-8601 string as a fallback. Returns empty if missing/unparseable.
time_until() {
  local ts="$1"
  [ -z "$ts" ] && return
  local epoch
  if [[ "$ts" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    # Unix epoch seconds (may be float — strip fractional part)
    epoch="${ts%.*}"
  else
    # Fallback: try ISO-8601 (normalize Z → +0000 for BSD date)
    local clean
    clean=$(echo "$ts" | sed -E 's/\.[0-9]+Z$/Z/' | sed 's/Z$/+0000/')
    epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$clean" "+%s" 2>/dev/null)
  fi
  [ -z "$epoch" ] && return
  local now diff
  now=$(date "+%s")
  diff=$((epoch - now))
  [ "$diff" -le 0 ] && { echo "now"; return; }
  fmt_duration "$diff"
}

# Git branch and dirty flag (skip optional locks to avoid blocking)
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    dirty=$(git -C "$cwd" -c gc.auto=0 status --porcelain 2>/dev/null | head -1)
    [ -n "$dirty" ] && branch="${branch}*"
    branch=" ${YELLOW}${branch}${RESET}"
  fi
fi

# Permission mode badge — color-coded by safety
perm_badge=""
case "$perm_mode" in
  default|"")          ;;  # hide for default
  plan)                perm_badge=" ${CYAN}plan${RESET}" ;;
  acceptEdits)         perm_badge=" ${YELLOW}accept-edits${RESET}" ;;
  bypassPermissions)   perm_badge=" ${BOLD_RED}bypass${RESET}" ;;
  auto)                perm_badge=" ${GREEN}auto${RESET}" ;;
  dontAsk)             perm_badge=" ${MAGENTA}no-ask${RESET}" ;;
  *)                   perm_badge=" ${GREY}${perm_mode}${RESET}" ;;
esac

# Session duration badge
duration_badge=""
if [ -n "$duration_ms" ] && [ "$duration_ms" != "null" ]; then
  duration_s=$((duration_ms / 1000))
  if [ "$duration_s" -gt 0 ]; then
    duration_badge=" ${GREY}$(fmt_duration "$duration_s")${RESET}"
  fi
fi

# Current context size — take latest message's input + cache tokens
# (Don't sum across messages: each turn re-sends the full context, so summing inflates wildly.)
tokens_pretty=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  total=$(jq -rs '
    [ .[] | select(.message.usage?) | .message.usage ] | last
    | ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))
  ' "$transcript" 2>/dev/null)
  if [ -n "$total" ] && [ "$total" != "null" ] && [ "$total" -gt 0 ]; then
    tokens_pretty=$(awk -v n="$total" 'BEGIN {
      if (n >= 1000000) printf "%.1fM", n/1000000;
      else if (n >= 1000) printf "%.1fk", n/1000;
      else printf "%d", n;
    }')
  fi
fi

# Compacted-context fraction — size of the carried-forward summary from the most
# recent compaction (compact_boundary.postTokens) as a fraction of current context.
comp_frac=0
if [ -n "$transcript" ] && [ -f "$transcript" ] && [ -n "$total" ] && [ "$total" != "null" ] && [ "$total" -gt 0 ]; then
  post_tokens=$(jq -rs '[ .[] | select(.subtype? == "compact_boundary") | .compactMetadata.postTokens // empty ] | last // empty' "$transcript" 2>/dev/null)
  if [ -n "$post_tokens" ] && [ "$post_tokens" -gt 0 ]; then
    comp_frac=$(awk -v p="$post_tokens" -v t="$total" 'BEGIN { f=p/t; if (f>1) f=1; print f }')
  fi
fi

# Context window bar (filled proportional to used_pct).
# Filled cells split into a compacted-summary segment (▓, dim) and fresh segment (█, bright).
context_line=""
if [ -n "$used_pct" ] || [ -n "$tokens_pretty" ]; then
  bar=""
  if [ -n "$used_pct" ]; then
    bar=$(awk -v p="$used_pct" -v w=20 -v cfrac="$comp_frac" \
          -v comp="$COMPACTED" -v hi="$HIGHLIGHT" -v lo="$GREY" -v r="$RESET" 'BEGIN {
      f = int((p/100)*w + 0.5);
      if (f > w) f = w;
      cc = int(f*cfrac + 0.5);          # compacted cells within the filled portion
      if (cc == 0 && cfrac > 0 && f > 0) cc = 1;  # always show ≥1 cell if a compaction exists
      if (cc > f) cc = f;
      printf "%s", comp;
      for (i=0; i<cc; i++) printf "▓";   # carried-over compaction summary
      printf "%s", hi;
      for (i=0; i<f-cc; i++) printf "█"; # fresh context since last compaction
      printf "%s", lo;
      for (i=0; i<w-f; i++) printf "░";  # free space
      printf "%s", r;
    }')
  fi
  tokens_badge=""
  [ -n "$tokens_pretty" ] && tokens_badge=" ${HIGHLIGHT}${tokens_pretty} tok${RESET}"
  pct_badge=""
  if [ -n "$used_pct" ]; then
    pct=$(printf '%.0f' "$used_pct")
    pct_badge=" ${GREY}${pct}%${RESET}"
  fi
  # Subscription rate-limit usage with reset-in times
  # (only present for Claude.ai subscribers after first API response)
  sub_parts=""
  if [ -n "$five_pct" ]; then
    f=$(printf '%.0f' "$five_pct")
    until_five=$(time_until "$five_reset")
    reset_in=""
    [ -n "$until_five" ] && reset_in=" ${GREY}(${until_five})${RESET}"
    sub_parts="${GREY}5h ${RESET}${FIVE_HR}${f}%${RESET}${reset_in}"
  fi
  if [ -n "$week_pct" ]; then
    w=$(printf '%.0f' "$week_pct")
    until_week=$(time_until "$week_reset")
    reset_in=""
    [ -n "$until_week" ] && reset_in=" ${GREY}(${until_week})${RESET}"
    sep=""
    [ -n "$sub_parts" ] && sep=" ${GREY}·${RESET} "
    sub_parts="${sub_parts}${sep}${GREY}7d ${RESET}${SEVEN_DAY}${w}%${RESET}${reset_in}"
  fi
  sub_badge=""
  [ -n "$sub_parts" ] && sub_badge=" ${GREY}[${RESET}${sub_parts}${GREY}]${RESET}"
  context_line=$'\n'"${bar}${tokens_badge}${pct_badge}${sub_badge}"
fi

# Model badge
model_badge=""
[ -n "$model" ] && model_badge=" ${GREY}${model}${RESET}"

printf "%s%s%s%s%s%s%s%s" "$BLUE" "$short_dir" "$RESET" "$branch" "$model_badge" "$perm_badge" "$duration_badge" "$context_line"
