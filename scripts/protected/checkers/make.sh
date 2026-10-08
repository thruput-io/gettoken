#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "$(dirname "$0")/common.sh"

report=${1:?make.sh: name the report to check}

kind=${3:?make.sh: name the stat that counts the files checked}
minimum_name=${4:?make.sh: name the threshold holding the minimum number of files}
minimum=${!minimum_name}
files=$(stat "$kind")
issues=$(jq -s 'add | length' "$report")
echo "checkmake: $issues issues (max $CHECKMAKE_MAX_ISSUES, $files $kind checked, min $minimum)"
[ "$issues" -le "$CHECKMAKE_MAX_ISSUES" ] && [ "$files" -ge "$minimum" ]
