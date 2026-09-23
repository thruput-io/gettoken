#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2163
set -euo pipefail

ensure_bash5() {
  if (( BASH_VERSINFO[0] < 5 )); then
    local hb_bash=""
    if [ -x /opt/homebrew/bin/bash ]; then
      hb_bash="/opt/homebrew/bin/bash"
    elif [ -x /usr/local/bin/bash ]; then
      hb_bash="/usr/local/bin/bash"
    fi

    if [ -n "$hb_bash" ]; then
      echo "Error: Bash 5 or higher is required (found version ${BASH_VERSION}). Homebrew Bash is installed at '$hb_bash', but it is not first in your PATH. Please update your PATH." >&2
    else
      echo "Error: Bash 5 or higher is required (found version ${BASH_VERSION}). Please install Bash 5 via Homebrew or check your PATH." >&2
    fi
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
    if [[ -n "${!var_name:-}" ]]; then
      val="${!var_name}"
      printf 'export %s\n' "$var_name"
      if [[ "$val" == *$'\n'* ]]; then
        printf 'define %s\n%s\nendef\n' "$var_name" "$val"
      else
        printf '%s := %s\n' "$var_name" "$val"
      fi
    fi
  done
}

source "$ROOT_DIR/constants.env"

if [ "${CI:-}" = "true" ]; then
  required BRANCH ARCHIVE_SIGNING_KEY
  SITE_URL=$PROD_SITE_URL
else
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  SITE_URL=$LOCAL_SITE_URL

  ARCHIVE_SIGNING_KEY=$(bash scripts/generate-key.sh)
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

export ROOT_DIR BRANCH SITE_URL PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS ARCHIVE_SIGNING_KEY
expose ROOT_DIR BRANCH SITE_URL PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS ARCHIVE_SIGNING_KEY