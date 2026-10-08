#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?kcov.sh: name the report to write}
outdir=${3:?kcov.sh: name the directory to write coverage into}
mapfile -t files < <(files_of shell | grep '\.bats$')
kcov --clean --bash-parser="$(command -v bash)" --bash-parse-files-in-dir=src --include-path=src \
  --exclude-pattern=.bats,/bats-core/,/Cellar/bats-core/ "$outdir" bats "${files[@]}" > "$report"
