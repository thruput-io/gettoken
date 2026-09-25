#!/usr/bin/env bash
set -euo pipefail

packages=${1:?archive-brew.sh: name the directory holding the brew formulae}
root=${2:?archive-brew.sh: name the directory to build the tap repository in}

mkdir -p "$root"
root=$(CDPATH='' cd "$root" && pwd)
packages=$(CDPATH='' cd "$packages" && pwd)

rm -rf "${root:?}"/* "${root:?}"/.git

git -C "$root" init --quiet
git -C "$root" config user.name "Agent"
git -C "$root" config user.email "agent@thruput.io"

mkdir -p "$root/Formula"
cp -a "$packages/Formula"/* "$root/Formula/"

git -C "$root" add Formula
git -C "$root" commit --quiet -m "Deliver Homebrew tap formulae"
git -C "$root" update-server-info

echo "$(find "$root/Formula" -name '*.rb' | wc -l | tr -d ' ') formulae archived in tap $root"
