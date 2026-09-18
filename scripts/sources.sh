#!/bin/bash
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "usage: sources.sh ROOT SUITE URL" >&2
  exit 1
fi
root=$1
suite=$2
url=$3

{
  echo 'Types: deb'
  echo "URIs: $url"
  echo "Suites: $suite"
  echo 'Components: main'
  echo 'Signed-By:'
  sed -e 's/^$/./' -e 's/^/ /' "$root/gettoken-archive-keyring.asc"
} > "$root/dists/$suite/gettoken.sources"

echo "$suite is reached at $url"
