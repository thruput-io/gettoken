#!/usr/bin/env bash
set -euo pipefail

cd "${ROOT_DIR:?reporters: name the ROOT_DIR}" || exit 1

tracked() {
  git ls-files --cached --others --exclude-standard -- "$@" | awk '!/\/vendor\//'
}

first_line() {
  tracked | tr '\n' '\0' | xargs -0 awk -v re="$1" "FNR == 1 && \$0 ~ re { print FILENAME } { nextfile }"
}

shell_files() {
  { tracked '*.sh' '*.bash' '*.bats'; first_line '^#!.*(sh|bats)$'; } | sort -u
}
