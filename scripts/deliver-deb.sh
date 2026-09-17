#!/bin/bash
set -euo pipefail

into=${1:?deliver-deb.sh: name a directory to deliver the packages into}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

cp -a "$root/src" "$build/source"
cp "$root/README.md" "$build/source/README.md"
"$root/scripts/packaging.sh" "$build/source"

(cd "$build/source" && dpkg-buildpackage -us -uc)

lintian --fail-on error,warning,info,pedantic,experimental --display-level '>=pedantic' "$build"/*.changes
echo "ok: lintian passes on the source and on every package, down to pedantic"

mkdir -p "$into"
into=$(CDPATH='' cd "$into" && pwd)

rm -f -- "$into"/*.deb "$into/Packages" "$into/Packages.gz" "$into/Release" \
    "$into/InRelease" "$into/Release.gpg"
cp "$build"/*.deb "$into"
(cd "$into" && dpkg-scanpackages -m . > Packages && gzip -kf Packages)
(cd "$into" && apt-ftparchive release .) > "$build/Release"
mv "$build/Release" "$into/Release"

echo
echo "$(find "$into" -name '*.deb' | wc -l) packages in $into, indexed for apt"
