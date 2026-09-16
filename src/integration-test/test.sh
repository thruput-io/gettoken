#!/bin/bash
set -euo pipefail

install_command=$1
unprivileged_user=$2

if [ -z "$install_command" ] || [ -z "$unprivileged_user" ]; then
  echo "test.sh: needs an install command and an unprivileged user" >&2
  exit 1
fi

$install_command gettoken integration-test-tool

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=/usr/lib/gettoken:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(sudo -u "$unprivileged_user" gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(sudo -u "$unprivileged_user" --preserve-env=INTEGRATIONTEST_TOKEN integration-test-tool)

echo "the tool ran on $ran_on as $unprivileged_user, and the super-token carried $carried"
test "$ran_on" = "$carried"
echo "ok: $carried went in as a super-token and came back out of the tool"
