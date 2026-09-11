#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: unpublish.sh BRANCH" >&2
  exit 1
fi
branch=$1

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
# shellcheck source=scripts/pages.sh
. "$root/scripts/pages.sh"

pages_open
trap pages_close EXIT

if [ ! -d "$pages/apt/dists/$branch" ]; then
  echo "unpublish.sh: the archive holds no snapshot for $branch" >&2
  exit 1
fi

rm -rf "${pages:?}/apt/dists/$branch" "${pages:?}/apt/pool/$branch"
pages_push "Unpublish $branch"
