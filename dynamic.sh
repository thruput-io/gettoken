#!/bin/bash
# shellcheck disable=SC2034,SC2163
set -euo pipefail

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
    export "$var_name"
    printf '%s := %s\n' "$var_name" "${!var_name}"
  done
}

source constants.env

if [ "${CI:-}" = "true" ]; then
  required BRANCH
  SITE_URL=$PROD_SITE_URL
else
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  SITE_URL=$LOCAL_SITE_URL
fi

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [ "$OS" = "linux" ]; then
  PACKAGE_FORMATS=$DEBIAN_PACKAGE_FORMATS
  INSTALL_COMMAND=$DEBIAN_INSTALL_COMMAND
  BUILD_DEPS=$DEBIAN_BUILD_DEPS
elif [ "$OS" = "darwin" ]; then
  PACKAGE_FORMATS=$DARWIN_PACKAGE_FORMATS
  INSTALL_COMMAND=$DARWIN_INSTALL_COMMAND
  BUILD_DEPS=$DARWIN_BUILD_DEPS
else
  echo "Unsupported OS: '$OS'" >&2
  exit 1
fi

expose BRANCH SITE_URL PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS