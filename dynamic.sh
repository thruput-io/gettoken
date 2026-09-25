#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2163
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

  for var_name in "$@"; do
    val="${!var_name}"
    printf 'export %s\n' "$var_name"
    if [[ "$val" == *$'\n'* ]]; then
      printf 'define %s\n%s\nendef\n' "$var_name" "$val"
    else
      printf '%s := %s\n' "$var_name" "$val"
    fi
  done
}

required ROOT_DIR
source "$ROOT_DIR/constants.env"

if [ "${CI:-}" = "true" ]; then
  required BRANCH ARCHIVE_SIGNING_KEY BUILD_NUMBER
  SITE_URL=$PROD_SITE_URL
else
  BRANCH=$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)
  SITE_URL=$LOCAL_SITE_URL
  ARCHIVE_SIGNING_KEY=$(bash "$ROOT_DIR/scripts/generate-key.sh")
  BUILD_NUMBER=0
fi

VERSION=$(<"$ROOT_DIR/version.txt").$BUILD_NUMBER

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [ "$OS" = "linux" ]; then
  PACKAGE_FORMATS=$DEBIAN_PACKAGE_FORMATS
  INSTALL_COMMAND=$DEBIAN_INSTALL_COMMAND
  BUILD_DEPS=$DEBIAN_BUILD_DEPS
  SEMGREP_INSTALL_COMMAND=$DEBIAN_SEMGREP_INSTALL_COMMAND
  BATS_LIB_PATH=$DEBIAN_BATS_LIB_PATH
  PATH_PREFIX=$DEBIAN_PATH_PREFIX
elif [ "$OS" = "darwin" ]; then
  PACKAGE_FORMATS=$DARWIN_PACKAGE_FORMATS
  INSTALL_COMMAND=$DARWIN_INSTALL_COMMAND
  BUILD_DEPS=$DARWIN_BUILD_DEPS
  SEMGREP_INSTALL_COMMAND=$DARWIN_SEMGREP_INSTALL_COMMAND
  BATS_LIB_PATH=$DARWIN_BATS_LIB_PATH
  PATH_PREFIX=$DARWIN_PATH_PREFIX
else
  echo "Unsupported OS: '$OS'" >&2
  exit 1
fi

required ROOT_DIR BRANCH SITE_URL PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS SEMGREP_INSTALL_COMMAND BATS_LIB_PATH PATH_PREFIX ARCHIVE_SIGNING_KEY BUILD_NUMBER VERSION
export ROOT_DIR BRANCH SITE_URL PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS SEMGREP_INSTALL_COMMAND BATS_LIB_PATH PATH_PREFIX ARCHIVE_SIGNING_KEY BUILD_NUMBER VERSION
expose ROOT_DIR BRANCH SITE_URL PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS SEMGREP_INSTALL_COMMAND BATS_LIB_PATH PATH_PREFIX ARCHIVE_SIGNING_KEY BUILD_NUMBER VERSION
