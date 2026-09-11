#!/bin/sh
set -eu

name=$1
into=$2

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

cp -a "$root" "$build/source"
rm -rf "$build/source/.git" "$build/source/build"
sh "$root/scripts/packaging.sh" "$name" "$build/source"

(cd "$build/source" && dpkg-buildpackage -us -uc)

lintian --fail-on error,warning,info,pedantic,experimental --display-level '>=pedantic' "$build"/*.changes
echo "ok: lintian passes on the source and on every package, down to pedantic"

mkdir -p "$into"
rm -f "$into"/*.deb
cp "$build"/*.deb "$into"

echo
echo "$(find "$into" -name '*.deb' | wc -l) packages built for $name in $into"
