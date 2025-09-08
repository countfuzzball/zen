#!/usr/bin/env bash
# Simple TUI image viewer for the terminal using chafa.
# Navigate with Left/Right arrows. Press 'q' to quit.
# Usage:
#   ./tiv.sh                # start at first image in current dir
#   ./tiv.sh IMG_0123.jpg   # start at that image (partial match ok)
#   ./tiv.sh 10             # start at index 10 (1-based)

set -Eeuo pipefail

# -------- Config --------
# File extensions to include (add/remove as you like)
EXTS=(jpg jpeg png webp gif bmp tiff tif avif heic heif jxl jp2)
# Status bar height lines to reserve (for filename/index)
STATUS_LINES=2

# -------- Helpers --------
cleanup() {
  tput cnorm || true
  stty echo 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Redraw current image
draw() {
  local cols lines maxh
  cols=$(tput cols)
  lines=$(tput lines)
  (( lines > STATUS_LINES )) || return

  clear
  # Header/status
  printf "[%d/%d] %s\n" "$((idx+1))" "${#FILES[@]}" "${FILES[$idx]}"
  printf "←/→: prev/next   q: quit\n"

  maxh=$((lines - STATUS_LINES))
  # Render with chafa scaled to terminal width x height
#  chafa --size="${cols}x${maxh}" --stretch --symbols=block --dither=none --polite \
#        --animate=off --preload "${FILES[$idx]}" 2>/dev/null || {


  chafa --size="${cols}x${maxh}" --stretch --symbols=block "${FILES[$idx]}" 2>/dev/null || {
    echo "Failed to render with chafa. Is it installed?"
  }
}

# Read a single key (with basic escape-seq handling for arrows)
read_key() {
  local k rest
  IFS= read -rsn1 k || return 1
  if [[ $k == $'\x1b' ]]; then
    # try to capture the rest of an arrow key sequence
    # Typical arrow seq: ESC [ D/C (left/right)
    IFS= read -rsn2 -t 0.01 rest || true
    echo -n "$k$rest"
  else
    echo -n "$k"
  fi
  return 0
}

# Build the file list (null-safe; sorted)
build_list() {
  local -a find_args
  find_args=( -maxdepth 1 -type f \( )
  local first=1
  for e in "${EXTS[@]}"; do
    if (( first )); then
      find_args+=( -iname "*.${e}" )
      first=0
    else
      find_args+=( -o -iname "*.${e}" )
    fi
  done
  find_args+=( \) -print0 )

  mapfile -d '' FILES < <(find . "${find_args[@]}" | LC_ALL=C sort -z)
  # Strip leading ./ for nicer display
  for i in "${!FILES[@]}"; do
    FILES[$i]="${FILES[$i]#./}"
  done
}

# Resolve start index from $1: numeric (1-based) or filename/partial
resolve_start_index() {
  local arg=$1
  # numeric?
  if [[ $arg =~ ^[0-9]+$ ]]; then
    local n=$((arg))
    if (( n >= 1 && n <= ${#FILES[@]} )); then
      idx=$((n-1))
      return
    fi
  fi
  # exact match first
  for i in "${!FILES[@]}"; do
    [[ "${FILES[$i]}" == "$arg" ]] && { idx=$i; return; }
  done
  # case-insensitive partial match
  local low_arg=${arg,,}
  for i in "${!FILES[@]}"; do
    [[ "${FILES[$i],,}" == *"$low_arg"* ]] && { idx=$i; return; }
  done
  # fallback: keep default 0
}

# -------- Main --------
command -v chafa >/dev/null 2>&1 || {
  echo "Error: chafa is not installed. Install it and try again."
  exit 1
}

tput civis || true  # hide cursor

FILES=()
build_list
if ((${#FILES[@]} == 0)); then
  echo "No images found in: $(pwd)"
  exit 1
fi

idx=0
if ((${#@} >= 1)); then
  resolve_start_index "$1"
fi

# Redraw on terminal resize
trap 'draw' WINCH

draw

# Main loop
while true; do
  key="$(read_key)" || break
  case "$key" in
    $'\x1b[D')  # Left arrow
      (( idx = (idx - 1 + ${#FILES[@]}) % ${#FILES[@]} ))
      draw
      ;;
    $'\x1b[C')  # Right arrow
      (( idx = (idx + 1) % ${#FILES[@]} ))
      draw
      ;;
    q|Q)
      break
      ;;
    "")
      # ignore
      ;;
    *)
      # Optional: add vim keys h/l
      if [[ $key == "h" ]]; then
        (( idx = (idx - 1 + ${#FILES[@]}) % ${#FILES[@]} ))
        draw
      elif [[ $key == "l" ]]; then
        (( idx = (idx + 1) % ${#FILES[@]} ))
        draw
      fi
      ;;
  esac
done
