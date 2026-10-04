#!/usr/bin/env bash
set -euo pipefail

dist=${1:?payload.sh: name the directory the packages were delivered into}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
dist=$(CDPATH='' cd "$dist" && pwd)

COPYFILE_DISABLE=1 tar -cf - -C "$root" constants.env version.txt dynamic.sh src/integration-test \
  -C "$(dirname "$dist")" "$(basename "$dist")"
