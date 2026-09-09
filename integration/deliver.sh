#!/bin/sh
set -eu

# Builds the packages for a target and leaves them where they can be installed
# from, as an apt repository rather than a pile of files: apt resolves what a
# package depends on out of the index beside it, so installing the one tool
# draws in the rest exactly as it would from any other archive.
name=$1
into=$2

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

cp -a "$root" "$build/source"
rm -rf "$build/source/.git" "$build/source/build"
sh "$root/integration/packaging.sh" "$name" "$build/source"

(cd "$build/source" && dpkg-buildpackage -us -uc)

mkdir -p "$into"
rm -f "$into"/*.deb "$into"/Packages "$into"/Packages.gz
cp "$build"/*.deb "$into"
(cd "$into" && dpkg-scanpackages -m . > Packages && gzip -kf Packages)

echo
echo "$(ls "$into"/*.deb | wc -l) packages in $into, indexed for apt"
