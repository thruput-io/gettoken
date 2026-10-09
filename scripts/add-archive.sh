#!/usr/bin/env bash
set -euo pipefail

root=${ROOT_DIR:?add-archive.sh: name the ROOT_DIR}

for fmt in ${PACKAGE_FORMATS:?add-archive.sh: name the PACKAGE_FORMATS whose archives to add}; do
  bash "$root/scripts/add-archive-$fmt.sh" "$root/build/dist/$fmt"
done
