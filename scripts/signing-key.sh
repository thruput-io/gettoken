#!/bin/bash
set -euo pipefail

into=$1

if [ -z "$into" ]; then
  echo "signing-key.sh: no directory to write the key into" >&2
  exit 1
fi

mkdir -p "$into"
into=$(CDPATH='' cd "$into" && pwd)

GNUPGHOME="$into/gnupg"
export GNUPGHOME
rm -rf -- "$into/gnupg"
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
