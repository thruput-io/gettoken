#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?go-vet.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${2:?go-vet.sh: name the report to write}
module=${3:?go-vet.sh: name the module to vet}
go -C "$module" vet -json -mod=vendor ./... > "$report"
