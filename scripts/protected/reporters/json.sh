#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?json.sh: name the report to write}
mapfile -t files < <(files_of json)
for file in "${files[@]}"; do
  jq empty "$file"
  printf '%s\tvalid\n' "$file"
done > "$report"
