#!/usr/bin/env bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

for fmt in ${PACKAGE_FORMATS:?remove-packages.sh: name the PACKAGE_FORMATS whose packages to remove}; do
  bash "$root/scripts/remove-packages-$fmt.sh"
done
