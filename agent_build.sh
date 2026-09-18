#!/bin/bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
cd "$root"

branch=local
site=gettoken-site

say() { printf '\n=== %s ===\n' "$1"; }

gone() { docker ps -aq -f "name=^$1\$" | xargs -r docker rm -f > /dev/null; }

the_tree() { COPYFILE_DISABLE=1 git ls-files -z | COPYFILE_DISABLE=1 tar --null --files-from - -cf -; }

reaches_the_archive='
  apt-get update -qq > /dev/null
  apt-get install -y -qq --no-install-recommends make perl > /dev/null
  apt-get install -y -qq --no-install-recommends curl ca-certificates > /dev/null
  curl -fsS http://archive/apt/dists/'"$branch"'/gettoken.sources -o /etc/apt/sources.list.d/gettoken.sources
  apt-get update -o APT::Update::Error-Mode=any
'

gone gettoken-builder
docker ps -aq --filter "volume=$site" | xargs -r docker rm -f > /dev/null
docker volume rm -f "$site" > /dev/null
docker volume create "$site" > /dev/null

say "build and sign the suite on ubuntu, in docker"
the_tree | docker run -i --name gettoken-builder --network host \
  -e "ARCHIVE_SIGNING_KEY=$(cat "$HOME/.gettoken-archive-key.asc")" \
  -e "branch=$branch" \
  --volume "$site:/work/build/site" debian:testing-slim sh -ec '
    mkdir -p /work && cd /work && tar xf -
    printf "%s" "$ARCHIVE_SIGNING_KEY" > "$HOME/.gettoken-archive-key.asc"
    cp config.local.sh.ubuntu.example config.local.sh
    apt-get update -qq > /dev/null
    apt-get install -y -qq --no-install-recommends make ca-certificates > /dev/null
    export GOFLAGS=-buildvcs=false
    make archive BRANCH="$branch"'


say "test on a clean debian slim"
the_tree | scripts/served.sh "$site" -i debian:testing-slim sh -ec "
    mkdir -p /work && cd /work && tar xf -
    $reaches_the_archive
    printf 'export INSTALL_COMMAND = apt-get install -y --no-install-recommends\n' > config.local.sh
    make test"

say "test on a clean ubuntu"
the_tree | scripts/served.sh "$site" -i ubuntu:24.04 sh -ec "
    mkdir -p /work && cd /work && tar xf -
    $reaches_the_archive
    printf 'export INSTALL_COMMAND = apt-get install -y --no-install-recommends\n' > config.local.sh
    make test"

say "everything the pipeline does, done here"
