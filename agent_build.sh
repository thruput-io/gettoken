#!/bin/bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
cd "$root"

source constants.env

site=gettoken-site

say() { printf '\n=== %s ===\n' "$1"; }

gone() { docker ps -aq -f "name=^$1\$" | xargs -r docker rm -f > /dev/null; }

the_tree() { (git ls-files; find .git) | COPYFILE_DISABLE=1 tar -cf - -T -; }

gone gettoken-builder
docker ps -aq --filter "volume=$site" | xargs -r docker rm -f > /dev/null
docker volume rm -f "$site" > /dev/null
docker volume create "$site" > /dev/null

say "build and sign the suite on ubuntu, in docker"
the_tree | docker run -i --name gettoken-builder --network host \
  -e "ARCHIVE_SIGNING_KEY=$(cat "$HOME/.gettoken-archive-key.asc")" \
  --volume "$site:/work/build/site" debian:testing-slim sh -ec '
    mkdir -p /work && cd /work && tar xf -
    chmod +x scripts/*.sh src/components/contract/build.sh src/components/entitlements/entitlements src/components/secret-manager/secret-put src/components/secret-manager/secret-get src/components/token-service/token-service src/tools/gettoken/bin/gettoken src/tools/gettoken/privileged/token-requester src/tools/integration-test-tool/privileged/exchangers/integrationtest src/tools/integration-test-tool/bin/integration-test-tool src/integration-test/test.sh src/debian/rules dynamic.sh 2>/dev/null || true
    printf "%s" "$ARCHIVE_SIGNING_KEY" > "$HOME/.gettoken-archive-key.asc"
    apt-get update && apt-get install -y -qq --no-install-recommends make git ca-certificates > /dev/null
    git config --global --add safe.directory "*"
    export GOFLAGS=-buildvcs=false
    make package'

say "test on a clean node slim"
the_tree | bash scripts/served.sh "$site" -i node:26-slim sh -ec '
    mkdir -p /work && cd /work && tar xf -
    chmod +x scripts/*.sh src/components/contract/build.sh src/components/entitlements/entitlements src/components/secret-manager/secret-put src/components/secret-manager/secret-get src/components/token-service/token-service src/tools/gettoken/bin/gettoken src/tools/gettoken/privileged/token-requester src/tools/integration-test-tool/privileged/exchangers/integrationtest src/tools/integration-test-tool/bin/integration-test-tool src/integration-test/test.sh src/debian/rules dynamic.sh 2>/dev/null || true
    apt-get update && apt-get install -y -qq --no-install-recommends make git ca-certificates > /dev/null
    git config --global --add safe.directory "*"
    make test'

say "everything the pipeline does, done here"
