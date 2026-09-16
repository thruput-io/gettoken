#!/bin/bash
set -euo pipefail

root=$1

candidates=$(mktemp)
selected=$(mktemp)
trap 'rm -f "$candidates" "$selected"' EXIT

if ! find "$root" -path "$root/.git" -prune -o -path "$root/build" -prune -o -type f -print > "$candidates"; then
  echo "lint.sh: could not walk $root, so the gate checked nothing" >&2
  exit 1
fi

declares_bash_on_its_first_line() {
  case $(head -n 1 "$1") in
    '#!/bin/bash'|'# shellcheck shell=bash') return 0 ;;
  esac
  return 1
}

while IFS= read -r file; do
  if declares_bash_on_its_first_line "$file"; then printf '%s\n' "$file"; fi
done < "$candidates" > "$selected"

if [ ! -s "$selected" ]; then
  echo "lint.sh: found no shell files under $root, so the gate checked nothing" >&2
  exit 1
fi

xargs shellcheck -s bash -x < "$selected"
echo "ok: shellcheck read $(wc -l < "$selected" | tr -d ' ') files and reported nothing"
