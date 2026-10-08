#!/usr/bin/env bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

for fmt in ${PACKAGE_FORMATS:?add-archive.sh: name the PACKAGE_FORMATS whose archives to add}; do
  bash "$root/scripts/add-archive-$fmt.sh" "$root/build/dist/$fmt"
done
