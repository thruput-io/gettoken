#!/usr/bin/env bash
set -euo pipefail

tracked() {
  git ls-files --cached --others --exclude-standard -- "$@" | awk '!/\/vendor\//'
}

first_line() {
  local files
  mapfile -t files < <(tracked)
  awk -v re="$1" 'FNR == 1 && $0 ~ re { print FILENAME } { nextfile }' "${files[@]}"
}

shell_files() {
  { tracked '*.sh' '*.bash' '*.bats'; first_line '^#!.*(sh|bats)$'; } | sort -u
}
