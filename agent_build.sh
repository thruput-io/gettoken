#!/bin/bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
cd "$root"

volume=gettoken-dist
built=$(mktemp -d)
trap 'rm -rf "$built"' EXIT

say() { printf '\n=== %s ===\n' "$1"; }

the_tree() { (git ls-files --cached --others --exclude-standard | grep -v '/$'; find .git) | COPYFILE_DISABLE=1 tar -cf - --no-recursion -T -; }

what_a_clean_machine_gets() { COPYFILE_DISABLE=1 tar -cf - constants.env version.txt dynamic.sh src/integration-test -C "$1" build/dist; }

docker ps -aq --filter "volume=$volume" | xargs -r docker rm -f > /dev/null
docker volume rm -f "$volume" > /dev/null
docker volume create "$volume" > /dev/null

say "build, as the build job does"
the_tree | docker run -i --rm -e BUILD_NUMBER --volume "$volume:/work/build/dist" debian:testing-slim sh -c '
    set -eu
    mkdir -p /work
    cd /work
    tar xf -
    apt-get update
    apt-get install -y --no-install-recommends make git ca-certificates
    git config --global --add safe.directory "*"
    make build'

mkdir -p "$built/debian/build/dist"
docker run --rm --volume "$volume:/dist:ro" debian:testing-slim tar -cf - -C /dist . | tar -xf - -C "$built/debian/build/dist"

say "install on a clean debian, as the Debian stable job does"
what_a_clean_machine_gets "$built/debian" | docker run -i --rm -e ROOT_DIR=/work -e BUILD_NUMBER debian:testing-slim bash -c '
    set -eu
    mkdir -p /work
    cd /work
    tar xf -
    source dynamic.sh > /dev/null
    bash -ec "$ADD_ARCHIVE"
    bash src/integration-test/test.sh'

if command -v macos-vm > /dev/null; then
  say "build on macOS, as the build macOS job does"
  macos-vm reset > /dev/null
  # shellcheck disable=SC2016 # expands in the macOS guest, not here
  the_tree | macos-vm shell bash -lc '
    set -eu
    rm -rf "$HOME/gettoken"
    mkdir "$HOME/gettoken"
    cd "$HOME/gettoken"
    tar -xf -
    make build'
  mkdir -p "$built/macos/build"
  # shellcheck disable=SC2016 # expands in the macOS guest, not here
  macos-vm shell bash -lc 'COPYFILE_DISABLE=1 tar -cf - -C "$HOME/gettoken/build" dist' | tar -xf - -C "$built/macos/build"

  say "install on a fresh macOS guest, as the macOS stable job does"
  macos-vm reset > /dev/null
  # shellcheck disable=SC2016 # expands in the macOS guest, not here
  what_a_clean_machine_gets "$built/macos" | macos-vm shell bash -lc '
    set -eu
    rm -rf "$HOME/gettoken"
    mkdir "$HOME/gettoken"
    cd "$HOME/gettoken"
    tar -xf -
    export ROOT_DIR="$HOME/gettoken"
    source dynamic.sh > /dev/null
    bash -ec "$ADD_ARCHIVE"
    bash src/integration-test/test.sh'
fi

say "everything the pipeline does before it releases, done here"
