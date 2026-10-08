#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?jsonschema.sh: name the report to write}
schema=${3:?jsonschema.sh: name the schema option, --check-metaschema or --builtin-schema=NAME}
linter=${4:?jsonschema.sh: name the file class to check}
mapfile -t files < <(files_of "$linter")
check-jsonschema "$schema" --output-format=json "${files[@]}" > "$report"
