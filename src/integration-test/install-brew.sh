#!/usr/bin/env bash
set -euo pipefail

dist=${1:?install-brew.sh: name the directory the formulae were delivered into}
tap=${BREW_TAP:?install-brew.sh: name the BREW_TAP the formulae depend on each other through}

tarball=$(find "$dist/brew" -name '*.tar.gz')
test -f "$tarball"

brew tap-new --no-git "$tap"
formulae=$(brew --repository "$tap")/Formula
mkdir -p "$formulae"

for formula in "$dist"/brew/*.rb; do
  sed "s|^  url .*|  url \"file://$tarball\"|" "$formula" > "$formulae/$(basename "$formula")"
done

brew install --build-from-source "$tap/integration-test-tool"
