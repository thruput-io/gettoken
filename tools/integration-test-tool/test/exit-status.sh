#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/../../.." && pwd)
export PATH="$root/tools/integration-test-tool/bin:$PATH"

command -v integration-test-tool > /dev/null || { echo "FAIL: integration-test-tool is not on PATH"; exit 1; }

refuses() {
  INTEGRATIONTEST_TOKEN="$1" integration-test-tool && status=0 || status=$?
  [ "$status" -eq 1 ] || { echo "FAIL: expected exit 1, got $status"; exit 1; }
}

echo "# integration-test-tool refuses to run without a token"
refuses ""
echo "ok: empty token refused"

echo
echo "# integration-test-tool refuses the super-token"
refuses integrationtest-supertoken
echo "ok: super-token refused"

echo
echo "# integration-test-tool accepts the token integrationtest/ci/run downgrades to"
INTEGRATIONTEST_TOKEN=integrationtest-ci-run-allowed integration-test-tool

echo
echo "PASS: integration-test-tool exit status"
