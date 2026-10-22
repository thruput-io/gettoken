#!/usr/bin/env bash
set -euo pipefail

cd "${ROOT_DIR:?test.sh: name the ROOT_DIR the packages were delivered under}"

install=${INSTALL_COMMAND:?test.sh: name the INSTALL_COMMAND}
remove=${REMOVE_PACKAGES:?test.sh: name the REMOVE_PACKAGES command}

leaving_nothing_behind() {
  rm -rf "$HOME/secrets/host-privileged/integrationtest"
  bash -ec "$remove"
}
trap leaving_nothing_behind EXIT

bash -ec "$install integration-test-tool"
echo "installed=integration-test-tool"

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

privileged_side_beside_gettoken=$(dirname "$(command -v gettoken)")/../lib/gettoken

PATH=$privileged_side_beside_gettoken:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN
echo "carried=$carried"

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)
echo "ran_on=$ran_on"

test "$ran_on" = "$carried" || {
  echo "integration-test: integrationtest/ci/run ran on '$ran_on', not on the '$carried' that was put in the store" >&2
  exit 1
}
