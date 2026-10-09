#!/usr/bin/env bash
set -euo pipefail

report=${1:?go-test.sh: name the report to write}
module=${2:?go-test.sh: name the module to test}
profile=${3:?go-test.sh: name the coverage profile to write}
go test -C "$module" -json -mod=vendor -coverprofile="$profile" ./... > "$report"
