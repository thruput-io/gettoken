#!/usr/bin/env bash
set -euo pipefail

archive=${1:?add-archive-brew.sh: name the directory holding the formulae}
tap=${BREW_TAP:?add-archive-brew.sh: name the BREW_TAP to add the formulae to}

brew tap-new --no-git "$tap"
brew trust "$tap"
cp "$archive"/*.rb "$(brew --repository "$tap")/Formula/"
