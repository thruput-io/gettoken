#!/usr/bin/env bash
set -euo pipefail

install_command=${1:-${INSTALL_COMMAND:?test.sh: name the INSTALL_COMMAND}}
branch=${2:-${BRANCH:?test.sh: name the BRANCH}}
site_url=${3:-${SITE_URL:?test.sh: name the SITE_URL}}

bash -ec "$install_command curl ca-certificates"
curl -fsS "$site_url/apt/dists/$branch/gettoken.sources" -o /etc/apt/sources.list.d/gettoken.sources
bash -ec "$install_command integration-test-tool gettoken"

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
