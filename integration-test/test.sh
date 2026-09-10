#!/bin/bash
set -euo pipefail

packages=$1

echo "deb [trusted=yes] file:$packages ./" > /etc/apt/sources.list.d/gettoken.list
apt-get update

apt-get install -y --no-install-recommends integration-test-tool

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=/usr/lib/gettoken:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

echo "the tool ran on $ran_on, and the super-token carried $carried"
test "$ran_on" = "$carried"
echo "ok: $carried went in as a super-token and came back out of the tool"
