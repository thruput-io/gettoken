#!/usr/bin/env bash
set -euo pipefail

into=${1:?deliver-brew.sh: name a directory to deliver the formulae into}
version=${VERSION:?deliver-brew.sh: name the VERSION}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

build=$root/build/package/brew
rm -rf "$build"
mkdir -p "$build"

name=gettoken-$version
cp -a "$root/src" "$build/$name"
cp "$root/README.md" "$build/$name/README.md"

mkdir -p "$into"
into=$(CDPATH='' cd "$into" && pwd)

tarball=$into/$name.tar.gz
COPYFILE_DISABLE=1 tar -czf "$tarball" -C "$build" "$name"
sha256=$(shasum -a 256 < "$tarball" | cut -d" " -f1)

BREW_URL="file://$tarball" BREW_SHA256="$sha256" "$root/scripts/packaging.sh" "$build/$name"

rm -f -- "$into"/*.rb
cp "$build/$name"/Formula/*.rb "$into"

echo "$(find "$into" -name '*.rb' | wc -l | tr -d ' ') formulae for $version in $into"
