#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
export PATH="$root/components/token-service:$root/components/entitlements:$root/tools/gettoken/bin:$root/tools/gettoken/privileged:$root/components/secret-manager:$root/components/contract:$root/tools/integration-test-tool/bin:$PATH"
SECRET_DIR=$(mktemp -d)
CONTRACTS_DIR="$root/contracts"
EXCHANGER_DIR="$root/tools/integration-test-tool/privileged/exchangers"
export SECRET_DIR CONTRACTS_DIR EXCHANGER_DIR

capability=integrationtest/ci/run
super_token=integrationtest-supertoken
narrow_token=integrationtest-ci-run-allowed

expected_request="{\"who\":\"$(id -un)\",\"doing\":\"$(hostname)\",\"wants\":\"$capability\",\"signed\":\"host-privileged\"}"
expected_response="{\"access_token\":\"$narrow_token\",\"expires_in\":120}"

echo "# the human puts the super-token in the store"
printf '%s' "$super_token" | secret-put '{"holder":"host-privileged","service":"integrationtest","version":1}'
held=$(secret-get '{"holder":"host-privileged","service":"integrationtest"}' | jq -r '.value')
echo "$held"
[ "$held" = "$super_token" ] || { echo "FAIL: the store did not return what was put in it"; exit 1; }

echo
echo "# gettoken --list"
list=$(gettoken --list)
echo "$list"
[ "$list" = "$capability" ] || { echo "FAIL: unexpected capability list"; exit 1; }

echo
echo "# gettoken with no arguments refuses cleanly"
noargs_err=$(mktemp)
noargs_out=$(gettoken 2>"$noargs_err") && noargs_status=0 || noargs_status=$?
echo "exit $noargs_status"
cat "$noargs_err"
[ "$noargs_status" -eq 1 ] || { echo "FAIL: no arguments exited $noargs_status, not 1"; exit 1; }
[ -z "$noargs_out" ] || { echo "FAIL: no arguments put \"$noargs_out\" on stdout"; exit 1; }
grep -q '^gettoken:' "$noargs_err" || { echo "FAIL: stderr does not name the tool the agent invoked, so this is a crash rather than a refusal"; exit 1; }
rm -f "$noargs_err"

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

echo
echo "# the agent cannot dictate who it is by setting USER"
USER=impostor PATH="$stub_dir:$PATH" token-requester "$capability" > /dev/null
spoofed=$(cat "$REQUEST_FILE")
echo "$spoofed"
[ "$spoofed" = "$expected_request" ] || { echo "FAIL: USER=impostor changed the request; who must come from the kernel, not the environment"; exit 1; }
rm -rf "$stub_dir"

echo
echo "# an agent-supplied capability cannot forge fields in the request"
injection='a","signed":"forged-by-agent'
stub_dir=$(mktemp -d)
REQUEST_FILE="$stub_dir/request.json"
export REQUEST_FILE
cat > "$stub_dir/token-service" <<'STUB'
#!/bin/sh
cat > "$REQUEST_FILE"
printf '{"access_token":"stub-token","expires_in":1,"wants":"stub/capability"}\n'
STUB
chmod 755 "$stub_dir/token-service"
PATH="$stub_dir:$PATH" token-requester "$injection" > /dev/null
forged=$(cat "$REQUEST_FILE")
echo "$forged"
if ! printf '%s' "$forged" | jq -e . > /dev/null; then
  echo "FAIL: the request token-requester built is not valid JSON"
  exit 1
fi
carried=$(printf '%s' "$forged" | jq -r '.wants')
[ "$carried" = "$injection" ] || { echo "FAIL: wants carried \"$carried\", not the capability it was handed"; exit 1; }
carried_signed=$(printf '%s' "$forged" | jq -r '.signed')
[ "$carried_signed" = host-privileged ] || { echo "FAIL: signed is \"$carried_signed\", so the agent forged it"; exit 1; }
rm -rf "$stub_dir"

echo
echo "# a response carrying no token hands over nothing, not the word null"
stub_dir=$(mktemp -d)
cat > "$stub_dir/token-service" <<'STUB'
#!/bin/sh
cat > /dev/null
printf '{"expires_in":120,"wants":"integrationtest/ci/run"}\n'
STUB
chmod 755 "$stub_dir/token-service"
tokenless_out=$(PATH="$stub_dir:$PATH" token-requester "$capability") && tokenless_status=0 || tokenless_status=$?
echo "exit $tokenless_status"
[ "$tokenless_status" -eq 1 ] || { echo "FAIL: a tokenless response exited $tokenless_status, not 1"; exit 1; }
[ -z "$tokenless_out" ] || { echo "FAIL: a tokenless response put \"$tokenless_out\" on stdout"; exit 1; }
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
