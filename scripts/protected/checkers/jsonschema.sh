#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "$(dirname "$0")/common.sh"

report=${1:?jsonschema.sh: name the report to check}

kind=${3:?jsonschema.sh: name the stat that counts the files checked}
minimum_name=${4:?jsonschema.sh: name the threshold holding the minimum number of files}
minimum=${!minimum_name}
files=$(stat "$kind")
status=$(jq -r '.status' "$report")
errors=$(jq '(.errors // []) + (.parse_errors // []) | length' "$report")
echo "check-jsonschema: $errors errors, status=$status (max $SCHEMAS_MAX_ERRORS, $files $kind checked, min $minimum)"
[ "$status" = "ok" ] && [ "$errors" -le "$SCHEMAS_MAX_ERRORS" ] && [ "$files" -ge "$minimum" ]
