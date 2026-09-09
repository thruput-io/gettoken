#!/bin/sh
set -eu

packages=$1

echo "deb [trusted=yes] file:$packages ./" > /etc/apt/sources.list.d/gettoken.list
apt-get update

apt-get install -y --no-install-recommends integration-test-tool

PATH=/usr/lib/gettoken:$PATH secret-put > /dev/null <<'SUPERTOKEN'
{"key":"host-privileged/integrationtest","value":"integrationtest-supertoken"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
integration-test-tool
