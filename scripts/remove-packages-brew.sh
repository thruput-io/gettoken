#!/usr/bin/env bash
set -euo pipefail

tap=${BREW_TAP:?remove-packages-brew.sh: name the BREW_TAP whose formulae to remove}

mapfile -t formulae < <(brew formulae | grep "^$tap/")
brew uninstall --formula "${formulae[@]}"
