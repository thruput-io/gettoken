#!/bin/bash
set -euo pipefail

root=$1
mode=${2:-}

cd "$root"

mkdir -p build
listing=$(mktemp)
trap 'rm -f "$listing"' EXIT

find . \
  \( -path ./.git -o -path ./build -o -path ./.idea -o -path ./.claude \
     -o -name vendor -o -name testdata \) -prune -o -type d -print \
  | sed 's|^\./||' \
  | grep -v '^\.$' \
  | sort \
  | awk -F/ '{
      indent = ""
      for (depth = 1; depth < NF; depth++) indent = indent "  "
      print indent $NF "/"
    }' > "$listing"

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
' README.md > build/readme.generated

if [ "$mode" = --write ]; then
  mv build/readme.generated README.md
  echo "README.md written from the tree"
else
  diff -u README.md build/readme.generated > /dev/null && result=same || result=drifted
  rm -f build/readme.generated
  if [ "$result" = drifted ]; then
    echo "readme.sh: README.md does not say what the tree holds. Run: make readme" >&2
    exit 1
  fi
  echo "ok: README.md says what the tree holds"
fi
