#!/bin/bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
cd "$root"

ROOT_DIR=$root
source "$root/dynamic.sh"

compose() { docker-compose -f scripts/docker/compose.yml -p gettoken-agent-build "$@"; }

say() { printf '\n=== %s ===\n' "$1"; }

the_tree() { (git ls-files --cached --others --exclude-standard | grep -v '/$'; find .git) | COPYFILE_DISABLE=1 tar -cf - -T -; }

reset_build_and_test() {
  compose rm -fsv builder test archive > /dev/null 2>&1 || true
  docker volume rm -f gettoken-agent-build_site > /dev/null 2>&1 || true
}

reset_build_and_test

say "build and sign the suite on ubuntu, in docker -- BUILD_DEPS is already baked into the image"
the_tree | compose run --rm -T builder sh -ec '
    mkdir -p /work && cd /work && tar xf -
    chmod +x scripts/*.sh src/components/contract/build.sh src/components/entitlements/entitlements src/components/secret-manager/secret-put src/components/secret-manager/secret-get src/components/token-service/token-service src/tools/gettoken/bin/gettoken src/tools/gettoken/privileged/token-requester src/tools/integration-test-tool/privileged/exchangers/integrationtest src/tools/integration-test-tool/bin/integration-test-tool src/integration-test/test.sh src/debian/rules dynamic.sh 2>/dev/null || true
    git config --global --add safe.directory "*"
    export GOFLAGS=-buildvcs=false
    make package'

say "test on a clean node slim: make test, then the same invocation CI uses"
the_tree | compose run --rm -T test bash -ec '
    mkdir -p /work && cd /work && tar xf -
    chmod +x scripts/*.sh src/components/contract/build.sh src/components/entitlements/entitlements src/components/secret-manager/secret-put src/components/secret-manager/secret-get src/components/token-service/token-service src/tools/gettoken/bin/gettoken src/tools/gettoken/privileged/token-requester src/tools/integration-test-tool/privileged/exchangers/integrationtest src/tools/integration-test-tool/bin/integration-test-tool src/integration-test/test.sh src/debian/rules dynamic.sh 2>/dev/null || true
    apt-get update && apt-get install -y -qq --no-install-recommends make git ca-certificates gnupg > /dev/null
    git config --global --add safe.directory "*"
    make test
    export ROOT_DIR=/work
    source dynamic.sh
    bash src/integration-test/test.sh'

reset_build_and_test

if command -v macos-vm > /dev/null; then
  say "build and package on a fresh macOS guest: PACKAGE_FORMATS=brew resolves here, nowhere else"
  macos-vm reset > /dev/null
  the_tree | macos-vm shell bash -lc '
    rm -rf "$HOME/gettoken" && mkdir "$HOME/gettoken" && cd "$HOME/gettoken" && tar -xf -
    export ROOT_DIR="$HOME/gettoken" CI=true BRANCH=agent-build ARCHIVE_SIGNING_KEY=agent-build-placeholder BUILD_NUMBER=0
    source dynamic.sh
    make package'
fi

say "everything the pipeline does, done here"
