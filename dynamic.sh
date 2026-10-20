#!/usr/bin/env bash
set -euo pipefail

ensure_bash5() {
  if (( BASH_VERSINFO[0] < 5 )); then
    echo "Error: Bash 5 or higher is required, found ${BASH_VERSION}. Put the Homebrew bash first in PATH." >&2
    exit 1
  fi
}

required() {
  for var_name in "$@"; do
    if [[ -z "${!var_name:-}" ]]; then
      echo "Error: Environment variable '$var_name' is required but unset or empty." >&2
      exit 1
    fi
  done
}

expose() {
  echo "# Generated from dynamic.sh"

  for pair in "$@"; do
    var_name=${pair%%=*}
    val=${pair#*=}
    val=${val//\$/\$\$}
    if [[ "$val" == *$'\n'* ]]; then
      printf 'define %s\n%s\nendef\nexport %s\n' "$var_name" "$val" "$var_name"
    else
      printf 'export %s := %s\n' "$var_name" "$val"
    fi
  done
}

required ROOT_DIR
source "$ROOT_DIR/constants.env"

VERSION=$(< "$ROOT_DIR/version.txt").${BUILD_NUMBER:-0}

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [ "$OS" = "linux" ]; then
  PACKAGE_FORMATS=$DEBIAN_PACKAGE_FORMATS
  INSTALL_COMMAND=$DEBIAN_INSTALL_COMMAND
  BUILD_DEPS=$DEBIAN_BUILD_DEPS
  SEMGREP_INSTALL_COMMAND=$DEBIAN_SEMGREP_INSTALL_COMMAND
  BATS_LIB_PATH=$DEBIAN_BATS_LIB_PATH
  PATH_PREFIX=$DEBIAN_PATH_PREFIX
  ADD_ARCHIVE=$DEBIAN_ADD_ARCHIVE
  REMOVE_PACKAGES=$DEBIAN_REMOVE_PACKAGES
elif [ "$OS" = "darwin" ]; then
  PACKAGE_FORMATS=$DARWIN_PACKAGE_FORMATS
  INSTALL_COMMAND=$DARWIN_INSTALL_COMMAND
  BUILD_DEPS=$DARWIN_BUILD_DEPS
  SEMGREP_INSTALL_COMMAND=$DARWIN_SEMGREP_INSTALL_COMMAND
  BATS_LIB_PATH=$DARWIN_BATS_LIB_PATH
  PATH_PREFIX=$DARWIN_PATH_PREFIX
  ADD_ARCHIVE=$DARWIN_ADD_ARCHIVE
  REMOVE_PACKAGES=$DARWIN_REMOVE_PACKAGES
else
  echo "Unsupported OS: '$OS'" >&2
  exit 1
fi

required ROOT_DIR VERSION BREW_TAP PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS SEMGREP_INSTALL_COMMAND BATS_LIB_PATH PATH_PREFIX ADD_ARCHIVE REMOVE_PACKAGES
expose \
  "ROOT_DIR=$ROOT_DIR" \
  "VERSION=$VERSION" \
  "BREW_TAP=$BREW_TAP" \
  "PACKAGE_FORMATS=$PACKAGE_FORMATS" \
  "INSTALL_COMMAND=$INSTALL_COMMAND" \
  "BUILD_DEPS=$BUILD_DEPS" \
  "SEMGREP_INSTALL_COMMAND=$SEMGREP_INSTALL_COMMAND" \
  "BATS_LIB_PATH=$BATS_LIB_PATH" \
  "PATH_PREFIX=$PATH_PREFIX" \
  "ADD_ARCHIVE=$ADD_ARCHIVE" \
  "REMOVE_PACKAGES=$REMOVE_PACKAGES"
