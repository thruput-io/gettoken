#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?checkmake.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${1:?checkmake.sh: name the report to write}
config=${2:?checkmake.sh: name the checkmake configuration}
mapfile -t files < <({ tracked ':(glob)**/Makefile'; first_line '^#!.*make'; } | sort -u)
checkmake --config="$config" -o json "${files[@]}" > "$report"
