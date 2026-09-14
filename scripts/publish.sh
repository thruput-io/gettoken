#!/bin/bash
set -euo pipefail

archive=$1
url=$2

if [ -z "$url" ]; then
  echo "publish.sh: no archive URL, so there is nowhere to publish to. Set ARCHIVE_URL" >&2
  exit 1
fi

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
# shellcheck source=scripts/pages.sh
. "$root/scripts/pages.sh"

signs_with=$(the_key_this_run_signs_with)

(
  cd "$archive"
  gpg --batch --yes --default-key "$signs_with" --clearsign --output InRelease Release
  gpg --batch --yes --default-key "$signs_with" --armor --detach-sign --sign --output Release.gpg Release
  gpg --export --export-options export-minimal "$signs_with" > gettoken-archive-keyring.gpg
)

echo "ok: Release is clearsigned as InRelease and detached as Release.gpg by $signs_with"

site=$(a_checkout_of_the_published_site)
trap 'rm -rf "$site"' EXIT

at=$(the_site_path_of "$url")
rm -rf "${site:?}/$at"
mkdir -p "$site/$at"
cp -a "$archive"/. "$site/$at"
the_site_keeps_what_jekyll_would_drop "$site"

the_published_site_takes_it "$site" "Publish $(basename "$archive") at $at"

echo "$(find "$archive" -name '*.deb' | wc -l) packages published to $url"
