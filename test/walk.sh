#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
export PATH="$root/bin:$PATH"
SECRET_DIR=$(mktemp -d)
export SECRET_DIR
printf 'super-token-dev-000' > "$SECRET_DIR/super-token"

capability=github/thruput-io/gettoken/read
expected_request="{\"who\":\"$USER\",\"doing\":\"$(hostname)\",\"wants\":\"$capability\",\"signed\":\"host-privileged\"}"
expected_response="{\"access_token\":\"super-token-dev-000\",\"expires_in\":3600,\"wants\":\"$capability\"}"

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
[ "$out" = "super-token-dev-000" ] || { echo "FAIL: gettoken did not return the token alone"; exit 1; }

echo
echo "PASS: chain runs end to end"
rm -rf "$SECRET_DIR"
