#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?go-vet.sh: name the report to write}
module=${3:?go-vet.sh: name the module to vet}
go -C "$module" vet -json -mod=vendor ./... > "$report"
