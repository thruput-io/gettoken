#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?bats.sh: name the report to write}
mapfile -t files < <(files_of shell | grep '\.bats$')
bats --timing --print-output-on-failure --formatter tap13 --report-formatter tap13 --output "$(dirname "$report")" "${files[@]}"
