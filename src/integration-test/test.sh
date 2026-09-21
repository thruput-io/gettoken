#!/bin/bash
set -euo pipefail

install_command=${1:-${INSTALL_COMMAND:?test.sh: name the command that installs a package}}

if [ -n "${SITE_URL:-}" ]; then
  branch=${BRANCH:-local}
  if ! command -v curl > /dev/null 2>&1; then
    sh -ec "$install_command curl ca-certificates" > /dev/null
  fi
  curl -fsS "$SITE_URL/apt/dists/$branch/gettoken.sources" -o /etc/apt/sources.list.d/gettoken.sources
fi

sh -ec "$install_command gettoken integration-test-tool" > /dev/null

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=/usr/lib/gettoken:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

test "$ran_on" = "$carried"
