# Indicator of pressing TMUX prefix.
# Emits its own colors:
#   - dim grey "<prefix>" label (e.g. "C-a") so it's obvious which key combo
#     activates the prefix on this server,
#   - then a red ● when prefix is held, dim ● otherwise.
# The theme renders this segment with bg=default + separator_disable.

run_segment() {
	local prefix
	prefix=$(tmux show -gv prefix 2>/dev/null)
	echo "#[fg=colour240]${prefix} #[default]#{?client_prefix,#[fg=red]●#[default],#[fg=colour240]●#[default]}"
	return 0
}
