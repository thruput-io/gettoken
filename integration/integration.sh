#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
export PATH="$root/components/token-service:$root/components/entitlements:$root/tools/gettoken/bin:$root/tools/gettoken/privileged:$root/components/secret-manager:$root/tools/integration-test-tool/bin:$root/tools/integration-test-tool/privileged:$PATH"
SECRET_DIR=$(mktemp -d)
export SECRET_DIR

capability=integrationtest/ci/run
super_token=integrationtest-supertoken
narrow_token=integrationtest-ci-run-allowed

expected_request="{\"who\":\"$USER\",\"doing\":\"$(hostname)\",\"wants\":\"$capability\",\"signed\":\"host-privileged\"}"
expected_response="{\"access_token\":\"$narrow_token\",\"expires_in\":120,\"wants\":\"$capability\"}"

echo "# the human puts the super-token in the store"
printf '%s' "$super_token" | secret-manager put integrationtest-super-token
held=$(secret-manager get integrationtest-super-token)
echo "$held"
[ "$held" = "$super_token" ] || { echo "FAIL: the store did not return what was put in it"; exit 1; }

echo
echo "# gettoken --list"
list=$(gettoken --list)
echo "$list"
[ "$list" = "$capability" ] || { echo "FAIL: unexpected capability list"; exit 1; }

echo
echo "# the request token-requester builds, captured by a stubbed token-service"
stub_dir=$(mktemp -d)
REQUEST_FILE="$stub_dir/request.json"
export REQUEST_FILE
cat > "$stub_dir/token-service" <<'STUB'
#!/bin/sh
cat > "$REQUEST_FILE"
printf '{"access_token":"stub-token","expires_in":1,"wants":"stub/capability"}\n'
STUB
chmod 755 "$stub_dir/token-service"
stub_out=$(PATH="$stub_dir:$PATH" token-requester "$capability")
request=$(cat "$REQUEST_FILE")
echo "$request"
[ "$request" = "$expected_request" ] || { echo "FAIL: request is not $expected_request"; exit 1; }
[ "$stub_out" = "stub-token" ] || { echo "FAIL: token-requester did not return the token alone"; exit 1; }
rm -rf "$stub_dir"

echo
echo "# the response token-service returns"
response=$(printf '%s' "$expected_request" | token-service)
echo "$response"
[ "$response" = "$expected_response" ] || { echo "FAIL: response is not $expected_response"; exit 1; }

echo
echo "# gettoken $capability"
out=$(gettoken "$capability")
echo "$out"
[ "$out" = "$narrow_token" ] || { echo "FAIL: gettoken did not return the downgraded token alone"; exit 1; }
[ "$out" != "$super_token" ] || { echo "FAIL: gettoken handed over the super-token"; exit 1; }

echo
echo "# the tool runs on what gettoken handed over"
INTEGRATIONTEST_TOKEN="$out" integration-test-tool

echo
echo "# the tool refuses the super-token, so the run above proves a downgrade"
if INTEGRATIONTEST_TOKEN="$super_token" integration-test-tool; then
  echo "FAIL: the tool accepted the super-token, so it cannot tell the two apart"
  exit 1
fi

echo
echo "# a capability no exchanger serves is refused, and hands over nothing"
unknown_out=$(gettoken nosuch/capability) && unknown_status=0 || unknown_status=$?
echo "exit $unknown_status"
[ "$unknown_status" -eq 1 ] || { echo "FAIL: an unserved capability exited $unknown_status, not 1"; exit 1; }
[ -z "$unknown_out" ] || { echo "FAIL: an unserved capability put $unknown_out on stdout"; exit 1; }

echo
echo "PASS: chain runs end to end"
rm -rf "$SECRET_DIR"
