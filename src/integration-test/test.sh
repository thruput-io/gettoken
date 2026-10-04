#!/usr/bin/env bash
set -euo pipefail

dist=${1:?test.sh: name the directory the packages were delivered into}
install_command=${INSTALL_COMMAND:?test.sh: name the INSTALL_COMMAND}

dist=$(CDPATH='' cd "$dist" && pwd)

bash -ec "$install_command $dist/deb/*.deb"

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=/usr/lib/gettoken:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

test "$ran_on" = "$carried"

apt-get purge -y gettoken-secret-manager
test ! -e /var/lib/gettoken
