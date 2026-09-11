#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: signing-key.sh FILE" >&2
  exit 1
fi
into=$1

home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
chmod 700 "$home"

gpg --homedir "$home" --batch --quiet --pinentry-mode loopback --passphrase '' \
    --quick-generate-key 'gettoken local archive <johan.granlund@thruput.se>' \
    default default never

mkdir -p "$(dirname "$into")"
gpg --homedir "$home" --batch --quiet --armor --export-secret-keys > "$into"
chmod 600 "$into"

echo "minted a throwaway signing key in $into"
