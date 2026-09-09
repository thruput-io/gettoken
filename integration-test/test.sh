#!/bin/sh
set -eu

packages=$1

echo "deb [trusted=yes] file:$packages ./" > /etc/apt/sources.list.d/gettoken.list
apt-get update

apt-get install -y --no-install-recommends integration-test-tool

key=host-privileged/integrationtest
value=integrationtest-supertoken
export key value
(
  PATH="/usr/lib/gettoken:$PATH"
  export PATH
  format secret-put-request.schema.json key value | secret-put > /dev/null
)

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
integration-test-tool
