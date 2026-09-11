#!/bin/bash
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "usage: publish.sh ARCHIVE BRANCH SITE-URL" >&2
  exit 1
fi
archive=$1
branch=$2
site=$3

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
# shellcheck source=scripts/pages.sh
. "$root/scripts/pages.sh"

corner_of_the_site_that_is_debian=apt

suites=$(cd "$archive/dists/$branch" && find . -name InRelease | sed 's|^\./||; s|/InRelease$||')

pages_open
trap pages_close EXIT

apt=$pages/$corner_of_the_site_that_is_debian
url=$site/$corner_of_the_site_that_is_debian

rm -rf "$apt/dists/$branch" "$apt/pool/$branch"
mkdir -p "$apt/dists/$branch" "$apt/pool/$branch"
cp -a "$archive/dists/$branch/." "$apt/dists/$branch/"
cp -a "$archive/pool/$branch/." "$apt/pool/$branch/"
cp "$archive/gettoken-archive-keyring.asc" "$apt/gettoken-archive-keyring.asc"
: > "$pages/.nojekyll"

for release in $suites; do
  "$root/scripts/sources.sh" "$apt" "$branch/$release" "$url"
done

pages_push "Publish $branch"

served=$(mktemp)
trap 'rm -f "$served"; pages_close' EXIT

for release in $suites; do
  suite="$branch/$release"
  pushed=$(sha256sum < "$archive/dists/$suite/InRelease" | cut -d' ' -f1)

  attempt=0
  while [ "$attempt" -lt 60 ]; do
    if curl --fail --silent --show-error --location \
         "$url/dists/$suite/InRelease" --output "$served"; then
      if [ "$(sha256sum < "$served" | cut -d' ' -f1)" = "$pushed" ]; then
        break
      fi
    fi
    attempt=$((attempt + 1))
    sleep 10
  done

  if [ "$attempt" -ge 60 ]; then
    echo "publish.sh: $url did not serve the pushed $suite within ten minutes" >&2
    exit 1
  fi
  echo "ok: $url serves the $suite that was just pushed"
done
