#!/bin/sh
set -eu

# Every shell file this tree carries, checked by the one gate. A file that is
# sourced rather than run carries no shebang, so it is selected by the directive
# that says which shell it is written for instead. Being selected is what gets it
# reported; -x only lets shellcheck read it for definitions when checking the
# files that source it, which is why -x alone left it unexamined.
root=$1

files=$(grep -rl -e '^#!/bin/sh' -e '^# shellcheck shell=sh' \
  --exclude-dir=.git --exclude-dir=build "$root") \
  || { echo "lint.sh: found no shell files under $root, so the gate checked nothing" >&2; exit 1; }

printf '%s\n' "$files" | xargs shellcheck -s sh -x
