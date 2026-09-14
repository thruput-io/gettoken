#!/bin/bash
set -euo pipefail

archive=$1
signing=$2

GNUPGHOME="$signing/gnupg"
export GNUPGHOME

signs_with=$(cat "$signing/fingerprint")

cd "$archive"
gpg --batch --yes --default-key "$signs_with" --clearsign --output InRelease Release
gpg --batch --yes --default-key "$signs_with" --armor --detach-sign --output Release.gpg Release

echo "ok: $archive carries InRelease and Release.gpg, signed by $signs_with"
