#!/bin/bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
cd "$root"

archive=package-archive

say() { printf '\n=== %s ===\n' "$1"; }

gone() { docker ps -aq -f "name=^$1\$" | xargs -r docker rm -f > /dev/null; }

the_tree() { COPYFILE_DISABLE=1 git ls-files -z | COPYFILE_DISABLE=1 tar --null --files-from - -cf -; }

reaches_the_archive='
  apt-get update -qq > /dev/null
  apt-get install -y -qq --no-install-recommends make curl ca-certificates perl > /dev/null
  mkdir -p /etc/apt/keyrings
  curl -fsS http://localhost:8080/deb/gettoken-archive-keyring.pgp \
    -o /etc/apt/keyrings/gettoken-archive-keyring.pgp
  echo "deb [signed-by=/etc/apt/keyrings/gettoken-archive-keyring.pgp] http://localhost:8080/deb ./" \
    > /etc/apt/sources.list.d/gettoken.list
  apt-get update -qq > /dev/null
'

say "the archive a developer publishes into"
gone "$archive"
docker run -d --name "$archive" -p 8080:80 nginx > /dev/null
docker inspect -f '{{.State.Running}}' "$archive"

say "build the deb on ubuntu, in docker"
gone gettoken-builder
the_tree | docker run -i --name gettoken-builder --network host \
  -e "ARCHIVE_KEY=$(cat "$HOME/.gettoken-archive-key.asc")" \
  -v /var/run/docker.sock:/var/run/docker.sock debian:testing-slim sh -ec '
    mkdir -p /work && cd /work && tar xf -
    printf "%s" "$ARCHIVE_KEY" > "$HOME/.gettoken-archive-key.asc"
    cp config.local.sh.ubuntu.example config.local.sh
    apt-get update -qq > /dev/null
    apt-get install -y -qq --no-install-recommends make docker-cli ca-certificates > /dev/null
    export GOFLAGS=-buildvcs=false
    make build'

say "test on a clean debian slim"
the_tree | docker run -i --rm --network host debian:testing-slim sh -ec "
    mkdir -p /work && cd /work && tar xf -
    $reaches_the_archive
    printf 'export INSTALL_COMMAND=\"apt-get install -y --no-install-recommends\"\n' > config.local.sh
    make test"

say "test on a clean ubuntu"
the_tree | docker run -i --rm --network host ubuntu:24.04 sh -ec "
    mkdir -p /work && cd /work && tar xf -
    $reaches_the_archive
    printf 'export INSTALL_COMMAND=\"apt-get install -y --no-install-recommends\"\n' > config.local.sh
    make test"

say "everything the pipeline does, done here"
