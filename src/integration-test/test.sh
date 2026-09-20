#!/bin/bash
set -euo pipefail

install_command=${1:?test.sh: name the command that installs a package}

sh -ec "$install_command gettoken integration-test-tool" > /dev/null

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

stored="{\"key\":\"host-privileged/integrationtest\",\"value\":\"super-$carried\"}"
PATH=/usr/lib/gettoken:$PATH secret-put "$stored" > /dev/null

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

held=$(mktemp -d)/token
gettoken -f "$held" integrationtest/ci/run
INTEGRATIONTEST_TOKEN=$(cat "$held")
ran_on_what_was_written=$(integration-test-tool)
closed=$(find "$held" -perm 600)

echo "TAP version 13"
echo "1..2"
test "$ran_on" = "$carried"
echo "ok 1 $carried went in as a super-token and came back out of the tool"
test "$ran_on_what_was_written" = "$carried"
test "$closed" = "$held"
echo "ok 2 the same token written to a file no other account can read ran the tool too"
