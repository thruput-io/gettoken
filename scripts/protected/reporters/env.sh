#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?env.sh: name the report to write}
mapfile -t files < <(files_of env)
name='(BREW_TAP|DEBIAN_[A-Z0-9_]+|DARWIN_[A-Z0-9_]+)'
awk -v single="^${name}='[^']*'\$" -v double="^${name}=\"[^\"\$\`\\\\\\\\]*\"\$" \
  '$0 != "" && $0 !~ single && $0 !~ double { print FILENAME ":" FNR "\t" $0 }' "${files[@]}" > "$report"
