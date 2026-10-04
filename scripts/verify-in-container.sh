#!/usr/bin/env bash
set -euo pipefail

dist=${1:?verify-in-container.sh: name the directory the packages were delivered into}

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

bash "$root/scripts/payload.sh" "$dist" \
  | docker run -i --rm -e BUILD_NUMBER debian:testing-slim bash -ec '
      mkdir -p /work && cd /work && tar xf -
      bash src/integration-test/clean-machine.sh "$0"' "$(basename "$dist")"
