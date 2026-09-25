#!/usr/bin/env bash
set -euo pipefail

temp_gpg_home=$(mktemp -d)
trap 'rm -rf "$temp_gpg_home"' EXIT
chmod 700 "$temp_gpg_home"

gpg --homedir "$temp_gpg_home" --batch --quiet --pinentry-mode loopback --passphrase '' \
  --quick-generate-key 'gettoken archive <johan.granlund@thruput.se>' default default never

key=$(gpg --homedir "$temp_gpg_home" --batch --quiet --list-secret-keys --with-colons | awk -F: '/^sec/ { print $5; exit }')
: "${key:?generate-key.sh: failed to retrieve key id}"

gpg --homedir "$temp_gpg_home" --batch --quiet --armor --export-secret-keys "$key"
