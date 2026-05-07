#!/usr/bin/env bash
set -euo pipefail

# repo_url | sparse_path | dest_name
#   dest_name empty  -> copy contents of sparse_path into ./skills/
#   dest_name set    -> copy sparse_path itself to ./skills/<dest_name>/
SOURCES=(
	"https://github.com/obra/superpowers.git|skills|"
	"https://github.com/jgraph/drawio-mcp.git|skill-cli/drawio|drawio"
)

TMP_DIR=""
cleanup() {
	if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
		rm -rf "$TMP_DIR"
	fi
}
trap cleanup EXIT

mkdir -p "./skills"

for entry in "${SOURCES[@]}"; do
	IFS='|' read -r repo sparse_path dest_name <<<"$entry"

	if TMP_DIR="$(mktemp -d 2>/dev/null)"; then
		:
	else TMP_DIR="$(mktemp -d -t get_skills)"; fi

	git clone --depth 1 --filter=blob:none --sparse "$repo" "$TMP_DIR"
	(cd "$TMP_DIR" && git sparse-checkout set "$sparse_path")

	if [[ -z "$dest_name" ]]; then
		cp -R "$TMP_DIR/$sparse_path/." "./skills/"
	else
		mkdir -p "./skills/$dest_name"
		cp -R "$TMP_DIR/$sparse_path/." "./skills/$dest_name/"
	fi

	rm -rf "$TMP_DIR"
	TMP_DIR=""
done

# Apply user-owned skill preference overlays.
# Each file in ./skill-preferences/<skill>.md is appended to the matching
# ./skills/<skill>/SKILL.md after the base skill is fetched.
PREFS_DIR="./skill-preferences"
if [[ -d "$PREFS_DIR" ]]; then
	for pref in "$PREFS_DIR"/*.md; do
		[[ -f "$pref" ]] || continue
		name="$(basename "$pref" .md)"
		skill_md="./skills/$name/SKILL.md"
		if [[ -f "$skill_md" ]]; then
			printf '\n' >>"$skill_md"
			cat "$pref" >>"$skill_md"
			echo "Applied overlay: $pref -> $skill_md"
		else
			echo "Skipping overlay $pref (no matching SKILL.md at $skill_md)"
		fi
	done
fi
