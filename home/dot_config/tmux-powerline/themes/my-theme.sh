# Default Theme

TMUX_POWERLINE_SEPARATOR_LEFT_BOLD=""
TMUX_POWERLINE_SEPARATOR_LEFT_THIN=""
TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=""
TMUX_POWERLINE_SEPARATOR_RIGHT_THIN=""

TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR:-'default'}
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR:-'255'}

TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD}
TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_LEFT_BOLD}

# See man tmux.conf for additional formatting options for the status line.
# The `format regular` and `format inverse` functions are provided as conveinences

# Vim-statusline (lualine on onedark) style — only the trailing right-sided
# rounded cap on each tab (no leading caps → no pill shape). The transition
# INTO the active tab comes from the *preceding inactive tab's* trailing cap,
# coloured so the bridge cap mirrors the active tab's own right cap
# (fg=#3b3f4c, bg=default, filled glyph) — symmetric rounded edges that
# blend into terminal bg. The active-vs-not check reads
# `@active_window_index` (set by the session-window-changed /
# client-attached / after-select-window hooks in the tmux configs) and
# compares it to `window_index + 1`.
#
#   active   → bg3 (#3b3f4c) with light fg (#abb2bf), trailing filled cap
#              fg=#3b3f4c bg=default — active bg curves out into terminal bg.
#   inactive (next tab is active) → trailing right-bulging filled cap
#              (RIGHT_BOLD = U+E0B4, same glyph as the active tab's own
#              right cap) over fg=#21252b bg=#3b3f4c. The disc fills the
#              LEFT half of the cell in #21252b (the onedark/Atom
#              One Dark accent the user uses as the terminal bg on both
#              Mac (Ghostty Atom One Dark) and Windows Terminal (theme bg
#              adjusted to match) — hardcoded; update if the terminal bg
#              changes) so it visually blends into terminal bg as a
#              'cutout', while the RIGHT half of the cell sits at bg
#              #3b3f4c, connecting smoothly into the active tab body.
#   inactive (otherwise) → trailing outline cap fg=#5c6370, bg=default — a
#              subtle separator on terminal bg.
if [ -z $TMUX_POWERLINE_WINDOW_STATUS_CURRENT ]; then
	TMUX_POWERLINE_WINDOW_STATUS_CURRENT=(
		"#[fg=#abb2bf,bg=#3b3f4c,nobold,noitalics,nounderscore]" \
		" #W " \
		"#[fg=#3b3f4c,bg=default,nobold,noitalics,nounderscore]" \
		"$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD" \
	)
fi

if [ -z $TMUX_POWERLINE_WINDOW_STATUS_STYLE ]; then
	TMUX_POWERLINE_WINDOW_STATUS_STYLE=(
		"fg=#5c6370,bg=default,nobold,noitalics,nounderscore"
	)
fi

if [ -z $TMUX_POWERLINE_WINDOW_STATUS_FORMAT ]; then
	# Trailing cap colour AND glyph are each selected by their own
	# `#{?cond,A,B}` rather than wrapping a whole `#[…]` style block in the
	# ternary. Wrapping forces tmux to escape inner commas as `,,`; tmux 3.5
	# unescapes those before parsing the style, but tmux 3.6 leaves the
	# `,,` in place, the style parser hits empty attribute tokens, and the
	# tail (`nounderscore]`) renders as literal text on the inactive tab
	# before the active one. Keeping each branch comma-free (one colour or
	# one glyph) sidesteps the escape entirely.
	TMUX_POWERLINE_WINDOW_STATUS_FORMAT=(
		"#[fg=#5c6370,bg=default,nobold,noitalics,nounderscore]" \
		" #W " \
		"#[fg=#{?#{e|==:#{e|+:#{window_index},1},#{@active_window_index}},#21252b,#5c6370},bg=#{?#{e|==:#{e|+:#{window_index},1},#{@active_window_index}},#3b3f4c,default},nobold,noitalics,nounderscore]" \
		"#{?#{e|==:#{e|+:#{window_index},1},#{@active_window_index}},${TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD},${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}}" \
	)
fi

# Format: segment_name background_color foreground_color [non_default_separator] [separator_background_color] [separator_foreground_color] [spacing_disable] [separator_disable]
#
# * background_color and foreground_color. Formats:
#   * Named colors (chech man page of tmux for complete list) e.g. black, red, green, yellow, blue, magenta, cyan, white
#   * a hexadecimal RGB string e.g. #ffffff
#   * 'default' for the defalt tmux color.
# * non_default_separator - specify an alternative character for this segment's separator
# * separator_background_color - specify a unique background color for the separator
# * separator_foreground_color - specify a unique foreground color for the separator
# * spacing_disable - remove space on left, right or both sides of the segment:
#   * "left_disable" - disable space on the left
#   * "right_disable" - disable space on the right
#   * "both_disable" - disable spaces on both sides
#   * - any other character/string produces no change to default behavior (eg "none", "X", etc.)
#
# * separator_disable - disables drawing a separator on this segment, very useful for segments
#   with dynamic background colours (eg tmux_mem_cpu_load):
#   * "separator_disable" - disables the separator
#   * - any other character/string produces no change to default behavior
#
# Example segment with separator disabled and right space character disabled:
# "hostname 33 0 {TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD} 33 0 right_disable separator_disable"
#
# Note that although redundant the non_default_separator, separator_background_color and
# separator_foreground_color options must still be specified so that appropriate index
# of options to support the spacing_disable and separator_disable features can be used

if [ -z $TMUX_POWERLINE_LEFT_STATUS_SEGMENTS ]; then
	TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
		# "tmux_session_info 148 234" \
		# "tmux_session_info 4 234" \
		# Prefix dot moved to the right segments below.
		# "my_mode_indicator default default ${TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD} default default left_disable separator_disable" \
		# Session-name tab on the far left, mirrors the active-window styling
		# (onedark bg3 + light fg) so the visual hierarchy is left→right:
		#   session ▶ inactive | inactive | [active ▶] ...
		"tmux_session_info #98c379 #21252b" \
		# "hostname 33 0" \
		#"ifstat 30 255" \
		#"ifstat_sys 30 255" \
		# "lan_ip 24 255 ${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}" \
		# "wan_ip 24 255" \
		# "vcs_branch 29 88" \
		#"vcs_compare 60 255" \
		#"vcs_staged 64 255" \
		#"vcs_modified 9 255" \
		#"vcs_others 245 0" \
	)
fi

if [ -z $TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS ]; then
	TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
		#"earthquake 3 0" \
		# "pwd 89 211" \
		#"macos_notification_count 29 255" \
		#"mailcount 9 255" \
		# "now_playing 234 37" \
		#"cpu 240 136" \
		# "load 237 167" \
		#"tmux_mem_cpu_load 234 136" \
		# "battery 2 234" \
		"my_mode_indicator default default ${TMUX_POWERLINE_SEPARATOR_LEFT_BOLD} default default left_disable separator_disable" \
		# "weather 37 255" \
		#"rainbarf 0 ${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR}" \
		#"xkb_layout 125 117" \
		# "date_day 235 136" \
		# "date 235 136 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}" \
		# "time 235 136 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}" \
		#"utc_time 235 136 ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}" \
	)
fi
