#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/thresholds.mk
source "$(dirname "${BASH_SOURCE[0]}")/../thresholds.mk"

stats=${2:?checkers: name the stats file to read}

stat() {
  awk -F': ' -v key="$1" '$1 == key { print $2 }' "$stats"
}
