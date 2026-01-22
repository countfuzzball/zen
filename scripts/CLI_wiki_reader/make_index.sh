#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-wiki_out}"
INDEX_OUT="${2:-wiki.index.tsv}"

# Clear output
: > "$INDEX_OUT"

# Normalise titles:
# - lowercase
# - underscores -> spaces
# - collapse whitespace
normalize_title() {
  tr '[:upper:]_' '[:lower:] ' \
  | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

export -f normalize_title

# Walk all wiki_* files
find "$ROOT" -type f -name 'wiki_*' | while read -r file; do
  # Use awk to track line numbers, jq to parse JSON
  awk '{print NR "\t" $0}' "$file" \
  | while IFS=$'\t' read -r lineno json; do
      # Extract id + title; skip invalid JSON quietly
      id="$(printf '%s\n' "$json" | jq -r '.id // empty' 2>/dev/null || true)"
      title="$(printf '%s\n' "$json" | jq -r '.title // empty' 2>/dev/null || true)"

      [[ -z "$id" || -z "$title" ]] && continue

      title_norm="$(printf '%s\n' "$title" | normalize_title)"
      echo "$title"

      printf '%s\t%s\t%s\t%s\t%s\n' \
        "$title_norm" \
        "$title" \
        "$id" \
        "$file" \
        "$lineno" >> "$INDEX_OUT"
    done
done
