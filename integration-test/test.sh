#!/bin/bash
set -euo pipefail

archive=$1
suite=$2

# shellcheck source=scripts/apt.sh
. "$(CDPATH='' cd "$(dirname "$0")/.." && pwd)/scripts/apt.sh"

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl

curl --fail --silent --show-error --location \
  "$archive/dists/$suite/gettoken.sources" \
  --output /etc/apt/sources.list.d/gettoken.sources

apt_takes_the_archive_or_stops "$archive"

apt-get install -y --no-install-recommends integration-test-tool

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=/usr/lib/gettoken:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

if [ "$ran_on" = "$carried" ]; then
  echo "ok: $carried went in as a super-token and came back out of the tool"
  exit 0
fi
echo "the tool ran on $ran_on, which is not what the super-token carried" >&2
exit 1
