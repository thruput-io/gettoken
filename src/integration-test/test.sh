#!/usr/bin/env bash
set -euo pipefail

cd "${ROOT_DIR:?test.sh: name the ROOT_DIR the packages were delivered under}"

bash -ec "${INSTALL_PACKAGES:?test.sh: name the INSTALL_PACKAGES command}"

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=${PRIVILEGED_PATH:?test.sh: name the PRIVILEGED_PATH}:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

test "$ran_on" = "$carried"

bash -ec "${REMOVE_PACKAGES:?test.sh: name the REMOVE_PACKAGES command}"
