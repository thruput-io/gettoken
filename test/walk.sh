#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
export PATH="$root/bin:$PATH"
SECRET_DIR=$(mktemp -d)
export SECRET_DIR
printf 'super-token-dev-000' > "$SECRET_DIR/super-token"

echo "# gettoken --list"
list=$(gettoken --list)
echo "$list"
[ "$list" = "github/thruput-io/gettoken/read" ] || { echo "FAIL: unexpected scope list"; exit 1; }

echo
echo "# token-requester github/thruput-io/gettoken/read, with token-service stubbed out to echo the request"
stub_dir=$(mktemp -d)
printf '#!/bin/sh\ncat\n' > "$stub_dir/token-service"
chmod +x "$stub_dir/token-service"
request=$(PATH="$stub_dir:$PATH" token-requester github/thruput-io/gettoken/read)
echo "$request"
expected_request="{\"who\":\"$USER\",\"doing\":\"$(hostname)\",\"wants\":\"github/thruput-io/gettoken/read\",\"signed\":\"host-privileged\"}"
[ "$request" = "$expected_request" ] || { echo "FAIL: request is not $expected_request"; exit 1; }
rm -rf "$stub_dir"

echo
echo "# gettoken github/thruput-io/gettoken/read"
out=$(gettoken github/thruput-io/gettoken/read)
echo "$out"
expected_response='{"access_token":"super-token-dev-000","expires_in":3600,"scope":"github/thruput-io/gettoken/read"}'
[ "$out" = "$expected_response" ] || { echo "FAIL: response is not $expected_response"; exit 1; }

echo
echo "PASS: chain runs end to end"
rm -rf "$SECRET_DIR"
