#!/usr/bin/env bash
set -euo pipefail

archive=${1:?publish.sh: name the archive to publish}
branch=${2:?publish.sh: name the branch whose suite is being published}
site=${3:?publish.sh: name the site the archive is served from}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=pages.sh
. "$root/scripts/pages.sh"

corner_of_the_site_that_is_debian=apt

pages_open
trap pages_close EXIT

for fmt in ${PACKAGE_FORMATS:-deb}; do
  case "$fmt" in
    deb)
      if [ -d "$archive" ]; then
        corner_of_the_site_that_is_debian=apt
        apt=$pages/$corner_of_the_site_that_is_debian
        url=$site/$corner_of_the_site_that_is_debian

        rm -rf "$apt/dists/$branch" "$apt/pool/$branch"
        mkdir -p "$apt/dists/$branch" "$apt/pool/$branch"
        cp -a "$archive/dists/$branch/." "$apt/dists/$branch/"
        cp -a "$archive/pool/$branch/." "$apt/pool/$branch/"
        cp "$archive/gettoken-archive-keyring.asc" "$apt/gettoken-archive-keyring.asc"
        : > "$pages/.nojekyll"

        "$root/scripts/sources.sh" "$apt" "$branch" "$url"

        pages_push "Publish $branch"

        served=$(mktemp)
        trap 'rm -f "$served"; pages_close' EXIT

        suite=$branch
        pushed=$(sha256sum < "$archive/dists/$suite/InRelease" | cut -d' ' -f1)
        served_now=""

        attempt=0
        while [ "$attempt" -lt 60 ] && [ "$served_now" != "$pushed" ]; do
          if curl --fail --silent --show-error --location \
            "$url/dists/$suite/InRelease" --output "$served"; then
            served_now=$(sha256sum < "$served" | cut -d' ' -f1)
          fi
          attempt=$((attempt + 1))
          if [ "$served_now" != "$pushed" ] && [ "$attempt" -lt 60 ]; then
            sleep 10
          fi
        done

        test "$served_now" = "$pushed"
        echo "ok: $url serves the $suite that was just pushed"
      fi
      ;;
    brew)
      mkdir -p "$pages/brew"
      : > "$pages/.nojekyll"
      if [ -f "build/dist/brew/gettoken.rb" ]; then
        cp "build/dist/brew/gettoken.rb" "$pages/brew/gettoken.rb"
      fi
      echo "ok: brew formula published"
      ;;
  esac
done
