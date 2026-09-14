#!/bin/bash
set -euo pipefail

into=$1

mkdir -p "$into"
GNUPGHOME="$into/gnupg"
export GNUPGHOME
rm -rf "$GNUPGHOME"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --batch --quiet --pinentry-mode loopback --passphrase '' \
    --quick-generate-key 'gettoken test archive <test@gettoken.invalid>' \
    default default never

gpg --list-secret-keys --with-colons \
  | awk -F: '/^fpr/ { print $10; exit }' > "$into/fingerprint"

gpg --export --export-options export-minimal "$(cat "$into/fingerprint")" \
  > "$into/pubkey.gpg"

echo "ok: test archive key $(cat "$into/fingerprint") in $into"
