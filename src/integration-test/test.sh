#!/usr/bin/env bash
set -euo pipefail

cd "${ROOT_DIR:?test.sh: name the ROOT_DIR the packages were delivered under}"

bash -ec "${INSTALL_COMMAND:?test.sh: name the INSTALL_COMMAND} integration-test-tool"

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

privileged_side_beside_gettoken=$(dirname "$(command -v gettoken)")/../lib/gettoken

PATH=$privileged_side_beside_gettoken:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

test "$ran_on" = "$carried"

rm -rf "$HOME/secrets/host-privileged/integrationtest"

bash scripts/remove-packages.sh
