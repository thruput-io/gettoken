#!/bin/bash
set -euo pipefail

bash -ec "$INSTALL_COMMAND curl ca-certificates"
curl -fsS "$SITE_URL/apt/dists/$BRANCH/gettoken.sources" -o /etc/apt/sources.list.d/gettoken.sources
bash -ec "$INSTALL_COMMAND integration-test-tool gettoken"

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=/usr/lib/gettoken:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

test "$ran_on" = "$carried" && echo "Integration test ran successfully"
