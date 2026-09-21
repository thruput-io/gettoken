#!/bin/bash
set -euo pipefail

root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
cd "$root"

set -a
source config.env
set +a

branch=local
site=gettoken-site

say() { printf '\n=== %s ===\n' "$1"; }

gone() { docker ps -aq -f "name=^$1\$" | xargs -r docker rm -f > /dev/null; }

the_tree() { COPYFILE_DISABLE=1 git ls-files -z | COPYFILE_DISABLE=1 tar --null --files-from - -cf -; }

gone gettoken-builder
docker ps -aq --filter "volume=$site" | xargs -r docker rm -f > /dev/null
docker volume rm -f "$site" > /dev/null
docker volume create "$site" > /dev/null

say "build and sign the suite on ubuntu, in docker"
the_tree | docker run -i --name gettoken-builder --network host \
  -e "ARCHIVE_SIGNING_KEY=$(cat "$HOME/.gettoken-archive-key.asc")" \
  -e "branch=$branch" \
  -e "SITE_URL=$LOCAL_SITE_URL" \
  --volume "$site:/work/build/site" debian:testing-slim sh -ec '
    mkdir -p /work && cd /work && tar xf -
    chmod +x scripts/*.sh src/components/contract/build.sh src/components/entitlements/entitlements src/components/secret-manager/secret-put src/components/secret-manager/secret-get src/components/token-service/token-service src/tools/gettoken/bin/gettoken src/tools/gettoken/privileged/token-requester src/tools/integration-test-tool/privileged/exchangers/integrationtest src/tools/integration-test-tool/bin/integration-test-tool src/integration-test/test.sh src/debian/rules 2>/dev/null || true
    printf "%s" "$ARCHIVE_SIGNING_KEY" > "$HOME/.gettoken-archive-key.asc"
    apt-get update && apt-get install -y -qq --no-install-recommends make > /dev/null
    export GOFLAGS=-buildvcs=false
    make package BRANCH="$branch" SITE_URL="$SITE_URL"'

say "test on a clean node slim"
the_tree | bash scripts/served.sh "$site" -i node:26-slim sh -ec "
    mkdir -p /work && cd /work && tar xf -
    bash src/integration-test/test.sh \"$DEBIAN_INSTALL_COMMAND\" \"$branch\" \"$LOCAL_SITE_URL\""

say "everything the pipeline does, done here"
