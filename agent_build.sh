#!/bin/bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
cd "$root"

volume=gettoken-dist
built=$(mktemp -d)
trap 'rm -rf "$built"' EXIT

say() { printf '\n=== %s ===\n' "$1"; }

the_tree() { (git ls-files --cached --others --exclude-standard | grep -v '/$'; find .git) | COPYFILE_DISABLE=1 tar -cf - -T -; }

what_a_clean_machine_gets() { COPYFILE_DISABLE=1 tar -cf - constants.env version.txt dynamic.sh src/integration-test -C "$built" build/dist; }

docker ps -aq --filter "volume=$volume" | xargs -r docker rm -f > /dev/null
docker volume rm -f "$volume" > /dev/null
docker volume create "$volume" > /dev/null

say "build, as the pipeline's build job does"
the_tree | docker run -i --rm -e BUILD_NUMBER --volume "$volume:/work/build/dist" debian:testing-slim sh -ec '
    mkdir -p /work && cd /work && tar xf -
    apt-get update && apt-get install -y --no-install-recommends make git ca-certificates
    git config --global --add safe.directory "*"
    make build'

mkdir -p "$built/build/dist"
docker run --rm --volume "$volume:/dist:ro" debian:testing-slim tar -cf - -C /dist . | tar -xf - -C "$built/build/dist"

say "install on a clean debian, as the Debian stable job does"
what_a_clean_machine_gets | docker run -i --rm -e ROOT_DIR=/work -e BUILD_NUMBER debian:testing-slim bash -c '
    mkdir -p /work && cd /work && tar xf -
    source dynamic.sh > /dev/null && bash src/integration-test/test.sh build/dist'

if command -v macos-vm > /dev/null; then
  say "install on a fresh macOS guest, as the macOS stable job does"
  macos-vm reset > /dev/null
  what_a_clean_machine_gets | macos-vm shell bash -lc '
    rm -rf "$HOME/gettoken" && mkdir "$HOME/gettoken" && cd "$HOME/gettoken" && tar -xf -
    export ROOT_DIR="$HOME/gettoken"
    source dynamic.sh > /dev/null && bash src/integration-test/test.sh build/dist'
fi

say "everything the pipeline does before it releases, done here"
