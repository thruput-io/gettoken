#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?branching.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${2:?branching.sh: name the report to write}
files_of shell | grep '\.bats$' | tr '\n' '\0' | xargs -0 awk '
  /^[[:space:]]*(if|elif|case)[[:space:]]/          { print FILENAME ": branches" }
  /\$\{[A-Za-z_][A-Za-z0-9_]*:[-=+?]/               { print FILENAME ": defaults a variable" }
' | sort -u > "$report"
