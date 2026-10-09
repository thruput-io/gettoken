#!/usr/bin/env bash
set -euo pipefail

ensure_bash5() {
  if (( BASH_VERSINFO[0] < 5 )); then
    echo "Error: Bash 5 or higher is required, found ${BASH_VERSION}. Put the Homebrew bash first in PATH." >&2
    exit 1
  fi
}

required() {
  local var_name
  for var_name in "$@"; do
    if [[ -z "${!var_name:-}" ]]; then
      echo "Error: Environment variable '$var_name' is required but unset or empty." >&2
      exit 1
    fi
  done
}

read_constants() {
  local file=$1 line
  local name='(BREW_TAP|DEBIAN_[A-Z0-9_]+|DARWIN_[A-Z0-9_]+)'
  local single="^${name}='([^']*)'\$"
  local double="^${name}=\"([^\"\$\`\\\\]*)\"\$"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      continue
    elif [[ "$line" =~ $single || "$line" =~ $double ]]; then
      printf -v "${BASH_REMATCH[1]}" '%s' "${BASH_REMATCH[2]}"
    else
      echo "Error: $file may hold only NAME='literal' or NAME=\"literal\" lines, found: $line" >&2
      exit 1
    fi
  done < "$file"
}

expose() {
  local var_name val
  echo "# Generated from dynamic.sh"

  for var_name in "$@"; do
    val="${!var_name}"
    if [[ "$val" == *$'\n'* || "$val" == *'#'* || "$val" == *\\ ]]; then
      echo "Error: $var_name holds a newline, a '#' or a trailing backslash, which make would not read as written." >&2
      exit 1
    fi
    val=${val//\$/\$\$}
    printf 'export %s\n' "$var_name"
    printf '%s := %s\n' "$var_name" "$val"
  done
}

required ROOT_DIR
read_constants "$ROOT_DIR/constants.env"

VERSION=$(< "$ROOT_DIR/version.txt").${BUILD_NUMBER:-0}
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: VERSION '$VERSION' is not MAJOR.MINOR.BUILD_NUMBER in digits; check version.txt and BUILD_NUMBER." >&2
  exit 1
fi

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

if [ "$OS" = "linux" ]; then
  platform=DEBIAN
elif [ "$OS" = "darwin" ]; then
  platform=DARWIN
else
  echo "Unsupported OS: '$OS'" >&2
  exit 1
fi

for setting in PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS SEMGREP_INSTALL_COMMAND BATS_LIB_PATH PATH_PREFIX; do
  platform_name=${platform}_$setting
  required "$platform_name"
  printf -v "$setting" '%s' "${!platform_name}"
done

required ROOT_DIR VERSION BREW_TAP PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS SEMGREP_INSTALL_COMMAND BATS_LIB_PATH PATH_PREFIX
export ROOT_DIR VERSION BREW_TAP PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS SEMGREP_INSTALL_COMMAND BATS_LIB_PATH PATH_PREFIX
expose ROOT_DIR VERSION BREW_TAP PACKAGE_FORMATS INSTALL_COMMAND BUILD_DEPS SEMGREP_INSTALL_COMMAND BATS_LIB_PATH PATH_PREFIX
