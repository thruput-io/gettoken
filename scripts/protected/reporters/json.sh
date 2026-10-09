#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?json.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${1:?json.sh: name the report to write}
mapfile -t files < <(tracked '*.json' ':!:*.schema.json')
for file in "${files[@]}"; do
  jq empty "$file"
  printf '%s\tvalid\n' "$file"
done > "$report"
