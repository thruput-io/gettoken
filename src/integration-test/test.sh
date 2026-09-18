#!/bin/bash
set -euo pipefail

install_command=${1:?test.sh: name the command that installs a package}

$install_command gettoken integration-test-tool > /dev/null

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=/usr/lib/gettoken:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

echo "TAP version 13"
echo "1..1"
test "$ran_on" = "$carried"
echo "ok 1 $carried went in as a super-token and came back out of the tool"
