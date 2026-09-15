#!/bin/bash
set -euo pipefail

name=$1
into=$2

if [ -z "$into" ]; then
  echo "deliver.sh: no directory to deliver the packages into" >&2
  exit 1
fi

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

cp -a "$root" "$build/source"
rm -rf "$build/source/.git" "$build/source/build"
"$root/scripts/packaging.sh" "$name" "$build/source"

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
