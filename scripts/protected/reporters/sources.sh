#!/usr/bin/env bash
set -euo pipefail

inventory=${1:?sources.sh: name the inventory to hash}
report=${2:?sources.sh: name the hash list to write}

cut -f2 "$inventory" | tr '\n' '\0' | xargs -0 sha256sum > "$report.new"
if cmp -s "$report.new" "$report"; then
  rm "$report.new"
else
  mv "$report.new" "$report"
fi
