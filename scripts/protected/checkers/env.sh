#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "${ROOT_DIR:?env.sh: name the ROOT_DIR}/scripts/protected/checkers/common.sh"

report=${1:?env.sh: name the report to check}

files=$(stat 'env files')
invalid=$(wc -l < "$report" | tr -d ' ')
echo "env: $invalid lines are not NAME='literal' or NAME=\"literal\" (max $ENV_MAX_INVALID, $files env files checked, min $ENV_FILES_MIN)"
[ "$invalid" -le "$ENV_MAX_INVALID" ] && [ "$files" -ge "$ENV_FILES_MIN" ]
