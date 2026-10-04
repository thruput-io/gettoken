#!/usr/bin/env bash
set -euo pipefail

tap=${BREW_TAP:?remove-brew.sh: name the BREW_TAP the formulae were installed from}

read -ra installed <<< "$(brew list --formula --full-name | grep "^$tap/" | tr '\n' ' ')"
brew uninstall --formula "${installed[@]}"
! brew list --formula --full-name | grep -q "^$tap/"
