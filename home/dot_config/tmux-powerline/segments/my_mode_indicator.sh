# Indicator of pressing TMUX prefix.

indicator=""
indicator_off=""
prefix_mode_fg="colour234"
bg="colour1"

run_segment() {
	echo "#{?client_prefix,${indicator},${indicator_off}}"
	return 0
}