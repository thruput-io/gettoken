#!/usr/bin/env bash
set -euo pipefail

into=${1:?deliver-brew.sh: name a directory to deliver the formulae into}
version=${VERSION:?deliver-brew.sh: name the VERSION}
release=${RELEASE_URL:?deliver-brew.sh: name the RELEASE_URL the tarball is downloaded from}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

name=gettoken-$version
cp -a "$root/src" "$build/$name"
cp "$root/README.md" "$build/$name/README.md"

mkdir -p "$into"
into=$(CDPATH='' cd "$into" && pwd)

tarball=$into/$name.tar.gz
tar -czf "$tarball" -C "$build" "$name"
sha256=$(sha256sum < "$tarball" | cut -d' ' -f1)

"$root/scripts/packaging.sh" "$build/$name"
"$root/scripts/brew-formulae.sh" "$build/$name" "$into" "$release/v$version/$name.tar.gz" "$sha256"
