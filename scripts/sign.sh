#!/bin/bash
set -euo pipefail

archive=$1
signing=$2

archive=$(CDPATH='' cd "$archive" && pwd)
signing=$(CDPATH='' cd "$signing" && pwd)

GNUPGHOME="$signing/gnupg"
export GNUPGHOME

signs_with=$(cat "$signing/fingerprint")

cd "$archive"
gpg --batch --yes --default-key "$signs_with" --clearsign --output InRelease Release
gpg --batch --yes --default-key "$signs_with" --armor --detach-sign --output Release.gpg Release

cp "$signing/pubkey.gpg" "$archive/gettoken-archive-keyring.pgp"

echo "ok: $archive carries InRelease, Release.gpg and gettoken-archive-keyring.pgp, signed by $signs_with"
