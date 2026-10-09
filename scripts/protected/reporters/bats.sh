#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?bats.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

outdir=${2:?bats.sh: name the directory bats writes report.tap into}
mapfile -t files < <(tracked '*.bats')
bats --timing --print-output-on-failure --formatter tap13 --report-formatter tap13 --output "$outdir" "${files[@]}"
