#!/usr/bin/env bash
set -euo pipefail

branch=${1:?unpublish.sh: name the branch whose suite is being removed}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
# shellcheck source-path=SCRIPTDIR
# shellcheck source=pages.sh
. "$root/scripts/pages.sh"

pages_open
trap pages_close EXIT

if [ ! -d "$pages/apt/dists/$branch" ]; then
  echo "unpublish.sh: the archive holds no snapshot for $branch" >&2
  exit 1
fi

rm -rf "${pages:?}/apt/dists/$branch" "${pages:?}/apt/pool/$branch"
pages_push "Unpublish $branch"
