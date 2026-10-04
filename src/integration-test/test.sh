#!/usr/bin/env bash
set -euo pipefail

dist=${1:?test.sh: name the directory the packages were delivered into}
format=${INSTALL_FORMAT:?test.sh: name the INSTALL_FORMAT this machine installs}
lib=${LIB_DIR:?test.sh: name the LIB_DIR the privileged half is installed into}

here=$(CDPATH='' cd "$(dirname "$0")" && pwd)
dist=$(CDPATH='' cd "$dist" && pwd)

bash "$here/install-$format.sh" "$dist"

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=$lib:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

test "$ran_on" = "$carried"

bash "$here/remove-$format.sh"
