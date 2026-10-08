#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?go-coverage.sh: name the report to write}
module=${3:?go-coverage.sh: name the module the profile covers}
profile=${4:?go-coverage.sh: name the coverage profile to read}
go -C "$module" tool cover -func="$profile" > "$report"
