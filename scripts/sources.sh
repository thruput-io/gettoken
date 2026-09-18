#!/bin/bash
set -euo pipefail

root=${1:?sources.sh: name the archive to write the sources file into}
suite=${2:?sources.sh: name the suite the sources file points at}
url=${3:?sources.sh: name the URL the archive is served from}

{
  echo 'Types: deb'
  echo "URIs: $url"
  echo "Suites: $suite"
  echo 'Components: main'
  echo 'Signed-By:'
  sed -e 's/^$/./' -e 's/^/ /' "$root/gettoken-archive-keyring.asc"
} > "$root/dists/$suite/gettoken.sources"

echo "$suite is reached at $url"
