#!/bin/bash
set -euo pipefail

into=${1:?signing-key.sh: name a directory to write the key into}
: "${ARCHIVE_SIGNING_KEY:?signing-key.sh: the archive has no key to sign with}"

mkdir -p "$into"
into=$(CDPATH='' cd "$into" && pwd)

GNUPGHOME="$into/gnupg"
export GNUPGHOME
rm -rf -- "$into/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf '%s' "$ARCHIVE_SIGNING_KEY" | gpg --batch --quiet --import

gpg --list-secret-keys --with-colons \
  | awk -F: '/^fpr/ { print $10; exit }' > "$into/fingerprint"

gpg --export --export-options export-minimal "$(cat "$into/fingerprint")" \
  > "$into/pubkey.gpg"

echo "ok: the archive signs with $(cat "$into/fingerprint")"
