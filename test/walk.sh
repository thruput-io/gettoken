#!/bin/sh
# Walking-skeleton test: runs the whole chain end to end and checks a
# token-exchange response comes out. Keep this green after every commit.
set -e

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
echo "# gettoken github/thruput-io/gettoken/read"
out=$(gettoken github/thruput-io/gettoken/read)
echo "$out"

echo "$out" | grep -q '"access_token"' || { echo "FAIL: no access_token in response"; exit 1; }
echo "$out" | grep -q '"scope":"github/thruput-io/gettoken/read"' || { echo "FAIL: scope not echoed"; exit 1; }

echo
echo "PASS: chain runs end to end"
rm -rf "$SECRET_DIR"
