#!/bin/bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
cd "$root"

out=$root/build/agent-build

say() { printf '\n=== %s ===\n' "$1"; }

rm -rf "$out"

say "build, as the pipeline's build job does"
bash scripts/build-in-container.sh "$out"

say "install on a clean debian, as the Debian stable job does"
bash scripts/verify-in-container.sh "$out/dist"

if command -v macos-vm > /dev/null; then
  say "install on a fresh macOS guest, as the macOS stable job does"
  macos-vm reset > /dev/null
  bash scripts/payload.sh "$out/dist" | macos-vm shell bash -lc '
    rm -rf "$HOME/gettoken" && mkdir "$HOME/gettoken" && cd "$HOME/gettoken" && tar -xf -
    bash src/integration-test/clean-machine.sh dist'
fi

say "everything the pipeline does before it releases, done here"
