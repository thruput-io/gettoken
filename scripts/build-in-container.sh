#!/usr/bin/env bash
set -euo pipefail

out=${1:?build-in-container.sh: name the directory the build writes into}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

mkdir -p "$out"
out=$(CDPATH='' cd "$out" && pwd)
test -z "$(find "$out" -mindepth 1 -print -quit)"

cd "$root"

(git ls-files --cached --others --exclude-standard | grep -v '/$'; find .git) \
  | COPYFILE_DISABLE=1 tar -cf - -T - \
  | docker run -i --rm -e BUILD_NUMBER -e OWNER="$(id -u):$(id -g)" \
      --volume "$out:/work/build" debian:testing-slim sh -ec '
        mkdir -p /work && cd /work && tar xf -
        apt-get update && apt-get install -y --no-install-recommends make git ca-certificates
        git config --global --add safe.directory /work
        status=0
        make build || status=$?
        chown -R "$OWNER" /work/build
        exit "$status"'
