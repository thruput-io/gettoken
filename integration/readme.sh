#!/bin/sh
set -eu

# Writes the parts of README.md that the tree already knows, between the markers
# that name them. What a directory holds is not something to keep in step by
# hand: it is read from what the repository carries, and the gate fails when the
# two have drifted.
#
# With no second argument this prints what README.md should say. With --write it
# says it.
root=$1
mode=${2:-}

cd "$root"

listing=$(mktemp)
trap 'rm -f "$listing"' EXIT

{
  echo 'contracts/'
  git -c safe.directory='*' ls-files 'contracts/*.schema.json' | sed 's|contracts/|  |'
  echo
  echo 'components/'
  for d in components/*/; do
    name=$(basename "$d")
    note=''
    if [ -f "$d/SEAT.md" ]; then note='SEAT.md'; fi
    if [ -d "$d/cmd" ]; then note='parse and format, in Go'; fi
    printf '  %-27s %s\n' "$name/" "$note" | sed 's/[[:space:]]*$//'
  done
  echo
  echo 'tools/'
  for d in tools/*/; do
    echo "  $(basename "$d")/"
    git -c safe.directory='*' ls-files "$d" | sed "s|$d||" | awk -F/ '{ print ($2 == "" ? $1 : $1 "/") }' | sort -u | sed 's/^/    /'
  done
  echo
  echo 'debian/'
  git -c safe.directory='*' ls-files 'debian/*' | sed 's|debian/||' | sed 's/^/  /'
  echo
  echo 'integration/'
  git -c safe.directory='*' ls-files 'integration/*' | sed 's|integration/||' | awk -F/ '{ print ($2 == "" ? $1 : $1 "/") }' | sort -u | sed 's/^/  /'
  echo
  echo 'exploratory/'
} > "$listing"

awk -v listing="$listing" '
  /^<!-- layout -->$/ {
    print
    print "```"
    while ((getline line < listing) > 0) print line
    print "```"
    skip = 1
    next
  }
  /^<!-- end layout -->$/ { skip = 0 }
  !skip { print }
' README.md > README.generated

if [ "$mode" = --write ]; then
  mv README.generated README.md
  echo "README.md written from the tree"
else
  diff -u README.md README.generated > /dev/null && result=same || result=drifted
  rm -f README.generated
  if [ "$result" = drifted ]; then
    echo "readme.sh: README.md does not say what the tree holds. Run: make readme" >&2
    exit 1
  fi
  echo "ok: README.md says what the tree holds"
fi
