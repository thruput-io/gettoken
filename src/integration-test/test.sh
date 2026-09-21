#!/bin/bash
set -euo pipefail

install_command=${1:-$INSTALL_COMMAND}

bash -ec "$install_command curl ca-certificates"
curl -fsS "$SITE_URL/apt/dists/${BRANCH:-local}/gettoken.sources" -o /etc/apt/sources.list.d/gettoken.sources
bash -ec "$install_command gettoken integration-test-tool"

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=/usr/lib/gettoken:$PATH secret-put <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

test "$ran_on" = "$carried"
