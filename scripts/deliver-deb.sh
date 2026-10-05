#!/usr/bin/env bash
set -euo pipefail

into=${1:?deliver-deb.sh: name a directory to deliver the packages into}
version=${VERSION:?deliver-deb.sh: name the VERSION}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

cp -a "$root/src" "$build/source"
cp "$root/README.md" "$build/source/README.md"
"$root/scripts/packaging.sh" "$build/source"
sed -i "1s/(.*)/($version)/" "$build/source/debian/changelog"

(cd "$build/source" && dpkg-buildpackage -us -uc)

lintian --fail-on error,warning,info,pedantic,experimental --display-level '>=pedantic' "$build"/*.changes
echo "ok: lintian passes on the source and on every package, down to pedantic"

mkdir -p "$into"
into=$(CDPATH='' cd "$into" && pwd)

rm -f -- "$into"/*.deb "$into"/Packages "$into"/Release
cp "$build"/*.deb "$into"
(cd "$into" && apt-ftparchive packages . > Packages && apt-ftparchive release . > "$build/Release" && mv "$build/Release" Release)

echo "$(find "$into" -name '*.deb' | wc -l) packages built and indexed in $into"
