#!/bin/sh
set -eu

# Writes the parts of README.md that the tree already knows, between the markers
# that name them. What a directory holds is not something to keep in step by
# hand: it is read off the tree, and the gate fails when the two have drifted.
#
# With no second argument this prints what README.md should say. With --write it
# says it.
root=$1
mode=${2:-}

cd "$root"

listing=$(mktemp)
trap 'rm -f "$listing"' EXIT

# What one directory holds, a directory told apart from a file by the slash it
# keeps. find rather than ls, and no -printf, because this runs on macOS too.
entries() {
  {
    find "$1" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sed 's|$|/|'
    find "$1" -mindepth 1 -maxdepth 1 ! -type d -exec basename {} \;
  } | sort
}

{
  echo 'contracts/'
  find contracts -maxdepth 1 -name '*.schema.json' -exec basename {} \; | sort | sed 's/^/  /'
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
    entries "$d" | sed 's/^/    /'
  done
  echo
  echo 'debian/'
  find debian -mindepth 1 -maxdepth 2 -type f | sed 's|debian/||' | sort | sed 's/^/  /'
  echo
  echo 'integration/'
  entries integration | sed 's/^/  /'
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
