#!/usr/bin/env bash
set -euo pipefail

root=${ROOT_DIR:?remove-packages.sh: name the ROOT_DIR}

for fmt in ${PACKAGE_FORMATS:?remove-packages.sh: name the PACKAGE_FORMATS whose packages to remove}; do
  bash "$root/scripts/remove-packages-$fmt.sh"
done
