#!/bin/bash
set -euo pipefail

report=$1
thresholds=$2
name=$3

measured=$(jq -r '.percent' "$report")
floor=$(jq -r ".\"$name\".percent" "$thresholds")

echo "$name: $measured% covered, floor $floor%"

jq -n -e --argjson m "$measured" --argjson f "$floor" '$m >= $f' > /dev/null
