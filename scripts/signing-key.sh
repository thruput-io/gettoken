#!/usr/bin/env bash
set -euo pipefail

into=${1:?signing-key.sh: name the file to write the key to}
: "${ARCHIVE_SIGNING_KEY:?signing-key.sh: the archive has no key to sign with}"

mkdir -p "$(dirname "$into")"
printf '%s\n' "$ARCHIVE_SIGNING_KEY" > "$into"
chmod 600 "$into"

home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
chmod 700 "$home"
gpg --homedir "$home" --batch --quiet --import "$into"

echo "ok: the archive signs with $(gpg --homedir "$home" --list-secret-keys --with-colons | awk -F: '/^fpr/ { print $10; exit }')"
