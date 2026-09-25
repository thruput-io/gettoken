#!/usr/bin/env bash
set -euo pipefail

into=${1:?deliver-brew.sh: name a directory to deliver the formulae into}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

cp -a "$root/src" "$build/source"
cp "$root/README.md" "$build/source/README.md"
"$root/scripts/packaging.sh" "$build/source"

mkdir -p "$into"
into=$(CDPATH='' cd "$into" && pwd)

rm -rf "${into:?}/Formula"
cp -a "$build/source/Formula" "$into/Formula"

echo "$(find "$into/Formula" -name '*.rb' | wc -l) formulae built in $into/Formula"
