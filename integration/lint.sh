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

# What the repository carries, not what happens to be lying in the tree: a file
# nobody committed is nobody's to keep green.
#
# safe.directory is set for this call alone because the tree is read from inside
# a container: the checkout belongs to whoever made it and the process is root,
# and git refuses a repository it did not expect to be handed. Nothing is written
# here, so there is nothing for that check to protect.
if ! git -c safe.directory='*' -C "$root" ls-files > "$candidates"; then
  echo "lint.sh: could not list what $root carries, so the gate checked nothing" >&2
  exit 1
fi

while IFS= read -r file; do
  case $(head -n 1 "$root/$file") in
    '#!/bin/sh'|'# shellcheck shell=sh') printf '%s\n' "$root/$file" ;;
  esac
done < "$candidates" > "$selected"

if [ ! -s "$selected" ]; then
  echo "lint.sh: found no shell files under $root, so the gate checked nothing" >&2
  exit 1
fi

xargs shellcheck -s sh -x < "$selected"
