#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?go-test.sh: name the report to write}
module=${3:?go-test.sh: name the module to test}
profile=${4:?go-test.sh: name the coverage profile to write}
go test -C "$module" -json -mod=vendor -coverprofile="$profile" ./... > "$report"
