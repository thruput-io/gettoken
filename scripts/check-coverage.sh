#!/usr/bin/env bash
set -euo pipefail

report=$1
floor=${2:-0}

measured=$(jq -r '.percent_covered // .percent' "$report")

echo "coverage: $measured% covered, floor $floor%"

jq -n -e --argjson m "$measured" --argjson f "$floor" '$m >= $f' > /dev/null
