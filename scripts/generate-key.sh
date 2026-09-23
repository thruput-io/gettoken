#!/bin/bash
set -euo pipefail

into=${1:?generate-key.sh: name the file to write the key to}

if [ -n "${ARCHIVE_SIGNING_KEY:-}" ]; then
  mkdir -p "$(dirname "$into")"
  printf '%s\n' "$ARCHIVE_SIGNING_KEY" > "$into"
  exit 0
fi

temp_gpg_home=$(mktemp -d)
trap 'rm -rf "$temp_gpg_home"' EXIT
chmod 700 "$temp_gpg_home"

gpg --homedir "$temp_gpg_home" --batch --quiet --pinentry-mode loopback --passphrase '' \
  --quick-generate-key 'gettoken archive <johan.granlund@thruput.se>' \
  default default never

key=$(gpg --homedir "$temp_gpg_home" --list-secret-keys --with-colons | awk -F: '/^sec/ { print $5; exit }')
mkdir -p "$(dirname "$into")"
gpg --homedir "$temp_gpg_home" --batch --quiet --armor --export-secret-keys "$key" > "$into"
chmod 600 "$into"
