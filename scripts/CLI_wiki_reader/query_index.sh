#!/bin/bash


rg -i "$*" wiki.index.tsv > /tmp/search
#cut -f 2 /tmp/search | nl -w 3 -s '..> '


#nl -ba -w3 -s'..> ' /tmp/search \
#| while IFS=$'\t' read -r n row; do
#    title="$(printf '%s\n' "$row" | cut -f1)"
#    path="$(printf '%s\n' "$row" | cut -f3)"
#    line="$(printf '%s\n' "$row" | cut -f4)"

    # Peek the JSON for that entry and test whether .text is empty
#    is_empty="$(
#      sed -n "${line}p" "$path" \
#      | jq -r '(.text // "") | length == 0'
#    )"

#    if [[ "$is_empty" == "true" ]]; then
#      printf '%3s..> %s [empty]\n' "$n" "$title"
#    else
#      printf '%3s..> %s\n' "$n" "$title"
#    fi
#  done

i=0
while IFS=$'\t' read -r norm title id path line; do
  ((i++))

  is_empty="$(
    sed -n "${line}p" "$path" \
    | jq -r '((.text // "") | length) == 0'
  )"

  if [[ "$is_empty" == "true" ]]; then
    printf '%3d..> %s [empty]\n' "$i" "$title"
  else
    printf '%3d..> %s\n' "$i" "$title"
  fi
done < /tmp/search


#cat /tmp/search


echo -n "Select entry: "
read -r matchline

matchline="$(sed -n "${matchline}p" /tmp/search)"

path="$(printf '%s\n' "$matchline" | cut -f4)"
line="$(printf '%s\n' "$matchline" | cut -f5)"

#sed -n "${line}p" "$path"

#sed -n "${line}p" "$path" | jq -r '.title, .url, (.text[0:400])'


#sed -n "${line}p" "$path" \
#| jq -r '.title, .url, "", (.text | gsub("\\\\n"; "\n\n") | gsub("\n"; "\n\n"))' \
#| python3 -c 'import sys, html; print(html.unescape(sys.stdin.read()), end="")'


sed -n "${line}p" "$path" \
| jq -r '.title, .url, "", (.text | gsub("\n"; "\n\n"))' \
| python3 -c 'import sys, html; print(html.unescape(sys.stdin.read()), end="")' | fold -s -w 100 | less
