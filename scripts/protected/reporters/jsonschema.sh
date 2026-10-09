#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?jsonschema.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${1:?jsonschema.sh: name the report to write}
schema=${2:?jsonschema.sh: name the schema option, --check-metaschema or --builtin-schema=NAME}
mapfile -t files < <(tracked "${@:3}")
check-jsonschema "$schema" --output-format=json "${files[@]}" > "$report"
