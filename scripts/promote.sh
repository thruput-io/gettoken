#!/bin/bash
set -euo pipefail

from=$1
to=$2

if [ -z "$from" ] || [ -z "$to" ]; then
  echo "promote.sh: promoting needs both URLs. Set ARCHIVE_URL and PROMOTED_URL" >&2
  exit 1
fi

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
# shellcheck source=scripts/pages.sh
. "$root/scripts/pages.sh"

site=$(a_checkout_of_the_published_site)
trap 'rm -rf "$site"' EXIT

leaves=$(the_site_path_of "$from")
arrives=$(the_site_path_of "$to")

test -f "$site/$leaves/InRelease"

rm -rf "${site:?}/$arrives"
mkdir -p "$site/$arrives"
cp -a "$site/$leaves"/. "$site/$arrives"
rm -rf "${site:?}/$leaves"

the_published_site_takes_it "$site" "Promote $leaves to $arrives"

echo "the archive that passed at $from now answers at $to"
