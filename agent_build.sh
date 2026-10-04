#!/bin/bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
cd "$root"

ROOT_DIR=$root
source "$root/dynamic.sh" > /dev/null

dist=gettoken-dist

say() { printf '\n=== %s ===\n' "$1"; }

gone() { docker ps -aq -f "name=^$1\$" | xargs -r docker rm -f > /dev/null; }

the_tree() { (git ls-files --cached --others --exclude-standard | grep -v '/$'; find .git) | COPYFILE_DISABLE=1 tar -cf - -T -; }

gone gettoken-builder
docker ps -aq --filter "volume=$dist" | xargs -r docker rm -f > /dev/null
docker volume rm -f "$dist" > /dev/null
docker volume create "$dist" > /dev/null

say "build the packages and the formulae on debian, in docker"
the_tree | docker run -i --name gettoken-builder \
  --volume "$dist:/work/build/dist" debian:testing-slim sh -ec '
    mkdir -p /work && cd /work && tar xf -
    apt-get update && apt-get install -y -qq --no-install-recommends make git ca-certificates > /dev/null
    git config --global --add safe.directory "*"
    export GOFLAGS=-buildvcs=false
    make build'

say "install what was built on a clean debian, the invocation CI uses"
tar -cf - constants.env version.txt dynamic.sh src/integration-test/test.sh \
  | docker run -i --rm --volume "$dist:/work/build/dist:ro" -e ROOT_DIR=/work debian:testing-slim bash -c '
    cd /work && tar xf -
    source dynamic.sh > /dev/null && bash src/integration-test/test.sh build/dist'

say "everything the pipeline does before it releases, done here"
