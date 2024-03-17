# Indicator of pressing TMUX prefix.

indicator=""
indicator_off=""
prefix_mode_fg="colour234"
bg="colour1"

run_segment() {
	prefix_indicator="#{?client_prefix,${indicator},${indicator_off}}"
	echo $prefix_indicator
	return 0
}