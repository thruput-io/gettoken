#!/bin/sh
set -eu

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
. "$root/integration/chain.sh"
export PATH="$root/components/token-service:$root/components/entitlements:$root/tools/gettoken/bin:$root/tools/gettoken/privileged:$root/components/secret-manager:$root/build/bin:$root/tools/integration-test-tool/bin:$PATH"
SECRET_DIR=$(mktemp -d)
CONTRACTS_DIR="$root/contracts"
EXCHANGER_DIR="$root/tools/integration-test-tool/privileged/exchangers"
export SECRET_DIR CONTRACTS_DIR EXCHANGER_DIR

capability=integrationtest/ci/run
super_token=integrationtest-supertoken
narrow_token=integrationtest-ci-run-allowed

expected_request="{\"doing\":\"$(hostname)\",\"signed\":\"host-privileged\",\"wants\":\"$capability\",\"who\":\"$(id -un)\"}"
expected_response="{\"access_token\":\"$narrow_token\",\"expires_in\":120}"

echo "# the human puts the super-token in the store"
printf '%s' "$super_token" \
  | format secret-put-request.schema.json key=host-privileged/integrationtest value@- \
  | secret-put
stored=$(format secret-get-request.schema.json key=host-privileged/integrationtest | secret-get)
printf '%s' "$stored" | parse secret-get-response.schema.json
held=$(printf '%s' "$stored" | jq -r '.value')
echo "$held"
[ "$held" = "$super_token" ] || { echo "FAIL: the store did not return what was put in it"; exit 1; }

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
echo "# the ask gettoken hands the privileged half"
asked=$(mktemp)
format ask.schema.json "wants=$capability" > "$asked"
cat "$asked"

echo
echo "# the request token-requester builds, captured by a stubbed token-service"
stub_dir=$(mktemp -d)
REQUEST_FILE="$stub_dir/request.json"
export REQUEST_FILE
cat > "$stub_dir/token-service" <<'STUB'
#!/bin/sh
cat > "$REQUEST_FILE"
printf '{"access_token":"stub-token","expires_in":60}\n'
STUB
chmod 755 "$stub_dir/token-service"
stub_out=$(PATH="$stub_dir:$PATH" token-requester < "$asked")
request=$(cat "$REQUEST_FILE")
echo "$request"
[ "$request" = "$expected_request" ] || { echo "FAIL: request is not $expected_request"; exit 1; }
[ "$stub_out" = "stub-token" ] || { echo "FAIL: token-requester did not return the token alone"; exit 1; }

echo
echo "# the agent cannot dictate who it is by setting USER"
USER=impostor PATH="$stub_dir:$PATH" token-requester < "$asked" > /dev/null
spoofed=$(cat "$REQUEST_FILE")
echo "$spoofed"
[ "$spoofed" = "$expected_request" ] || { echo "FAIL: USER=impostor changed the request; who must come from the kernel, not the environment"; exit 1; }
rm -rf "$stub_dir"

echo
echo "# a capability the contract does not admit never reaches token-service"
injection='a","signed":"forged-by-agent'
stub_dir=$(mktemp -d)
REQUEST_FILE="$stub_dir/request.json"
export REQUEST_FILE
cat > "$stub_dir/token-service" <<'STUB'
#!/bin/sh
cat > "$REQUEST_FILE"
printf '{"access_token":"stub-token","expires_in":60}\n'
STUB
chmod 755 "$stub_dir/token-service"
forged=$(mktemp)
printf '{"wants":"%s"}' "$injection" > "$forged"
refused_with 1 "a capability carrying quotes" \
  env PATH="$stub_dir:$PATH" token-requester < "$forged"
rm -f "$forged"
[ ! -f "$REQUEST_FILE" ] || { echo "FAIL: a refused capability still reached token-service"; exit 1; }
rm -rf "$stub_dir"

echo
echo "# a response carrying no token hands over nothing, not the word null"
stub_dir=$(mktemp -d)
cat > "$stub_dir/token-service" <<'STUB'
#!/bin/sh
cat > /dev/null
printf '{"expires_in":120}\n'
STUB
chmod 755 "$stub_dir/token-service"
refused_with 1 "a tokenless response" \
  env PATH="$stub_dir:$PATH" token-requester < "$asked"
rm -rf "$stub_dir"

echo
echo "# the response token-service returns"
response=$(printf '%s' "$expected_request" | token-service)
echo "$response"
[ "$response" = "$expected_response" ] || { echo "FAIL: response is not $expected_response"; exit 1; }

rm -f "$asked"

chain_runs "$capability" "$super_token" "$narrow_token"

echo
echo "# a program the agent puts earlier on PATH cannot stand in for one the"
echo "# privileged half runs, because gettoken puts the system directories ahead"
echo "# of whatever it inherited"
sabotage=$(mktemp -d)
for shadowed in sed id hostname ls sort tail cat; do
  cat > "$sabotage/$shadowed" <<'SABOTAGE'
#!/bin/sh
echo "sabotage: a program the agent placed on PATH ran" >&2
exit 1
SABOTAGE
  chmod 755 "$sabotage/$shadowed"
done
shadowed_out=$(PATH="$sabotage:$PATH" gettoken "$capability")
echo "$shadowed_out"
[ "$shadowed_out" = "$narrow_token" ] || { echo "FAIL: a program placed earlier on PATH stood in for one the privileged half runs"; exit 1; }
rm -rf "$sabotage"

echo
echo "PASS: chain runs end to end"
rm -rf "$SECRET_DIR"
