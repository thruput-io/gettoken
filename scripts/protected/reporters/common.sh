#!/usr/bin/env bash
set -euo pipefail

inventory=${1:?reporters: name the inventory to read}

files_of() {
  awk -F'\t' -v linter="$1" '$1 == linter { print $2 }' "$inventory"
}
