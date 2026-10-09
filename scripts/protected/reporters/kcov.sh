#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?kcov.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${1:?kcov.sh: name the report to write}
outdir=${2:?kcov.sh: name the directory to write coverage into}
mapfile -t files < <(tracked '*.bats')
ulimit -S -n 4096
kcov --clean --bash-parser="$(command -v bash)" --bash-parse-files-in-dir=src --include-path=src \
  --exclude-pattern=.bats,/bats-core/,/Cellar/bats-core/ "$outdir" bats "${files[@]}" > "$report"
