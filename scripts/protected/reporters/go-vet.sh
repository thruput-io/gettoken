#!/usr/bin/env bash
set -euo pipefail

report=${1:?go-vet.sh: name the report to write}
module=${2:?go-vet.sh: name the module to vet}
go -C "$module" vet -json -mod=vendor ./... > "$report"
