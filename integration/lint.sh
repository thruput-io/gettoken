#!/bin/sh
set -eu

# Every shell file this tree carries, checked by the one gate. A file that is
# sourced rather than run carries no shebang, so it says which shell it is
# written for with a directive instead. Both are read from the first line only:
# a shebang inside a heredoc is a file being written, not the file being read.
root=$1

candidates=$(mktemp)
selected=$(mktemp)
trap 'rm -f "$candidates" "$selected"' EXIT

if ! find "$root" -type f -not -path '*/.git/*' -not -path "$root/build/*" > "$candidates"; then
  echo "lint.sh: could not walk $root, so the gate checked nothing" >&2
  exit 1
fi

while IFS= read -r file; do
  case $(head -n 1 "$file") in
    '#!/bin/sh'|'# shellcheck shell=sh') printf '%s\n' "$file" ;;
  esac
done < "$candidates" > "$selected"

if [ ! -s "$selected" ]; then
  echo "lint.sh: found no shell files under $root, so the gate checked nothing" >&2
  exit 1
fi

xargs shellcheck -s sh -x < "$selected"
