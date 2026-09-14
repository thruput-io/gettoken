#!/bin/bash
set -euo pipefail

archive=$1
keyring=$2
list=$3

test -f "$archive/InRelease"

mkdir -p "$(dirname "$list")"
echo "deb [signed-by=$keyring] file:$archive ./" > "$list"

echo "ok: $list points apt at $archive, to be verified against $keyring"
