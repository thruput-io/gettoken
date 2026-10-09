#!/usr/bin/env bash
set -euo pipefail

report=${1:?go-coverage.sh: name the report to write}
module=${2:?go-coverage.sh: name the module the profile covers}
profile=${3:?go-coverage.sh: name the coverage profile to read}
go -C "$module" tool cover -func="$profile" > "$report"
