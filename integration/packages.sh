#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)

capability=integrationtest/ci/run
runtime="jq libjson-schema-modern-perl"
super_token=integrationtest-supertoken
narrow_token=integrationtest-ci-run-allowed
store=/var/lib/gettoken/secrets

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'; }

echo "# the packages are built from the source tree"
cp -a "$root" "$build/source"
rm -rf "$build/source/.git"
(cd "$build/source" && dpkg-buildpackage -us -uc -b)
ls "$build"/*.deb

echo
echo "# lintian passes on every package"
lintian "$build"/*.deb

echo
echo "# nothing the packages run on is on this base, so apt has to resolve every"
echo "# dependency they declare rather than find it already there"
for needed in $runtime; do
  ! installed "$needed" \
    || { echo "FAIL: $needed is already installed, so this run cannot show that apt draws it in"; exit 1; }
done
echo "ok: $runtime — none of them installed"

echo
echo "# apt installs the packages, and resolves what each declares it depends on"
apt-get update
apt-get install -y --no-install-recommends "$build"/*.deb

echo
echo "# apt drew in what the packages declare, so the declarations are load-bearing"
for needed in $runtime; do
  installed "$needed" \
    || { echo "FAIL: apt did not install $needed, so some package does not declare it"; exit 1; }
done
echo "ok: $runtime — all installed by apt"

echo
echo "# the agent's entry point is the only thing the packages put on a public PATH"
installed=$(dpkg-query -L gettoken gettoken-token-service gettoken-entitlements \
  gettoken-secret-manager gettoken-contract integration-test-tool-gettoken \
  | grep '^/usr/bin/' | sort)
echo "$installed"
[ "$installed" = /usr/bin/gettoken ] || { echo "FAIL: the packages put more than gettoken on a public PATH"; exit 1; }

echo
echo "# the exchanger directory belongs to root alone, because what is in it is run with the super-token in reach"
owned=$(find /usr/lib/gettoken/exchangers -maxdepth 0 -user root)
[ "$owned" = /usr/lib/gettoken/exchangers ] || { echo "FAIL: /usr/lib/gettoken/exchangers is not root-owned"; exit 1; }
writable=$(find /usr/lib/gettoken/exchangers -maxdepth 0 -perm /022)
[ -z "$writable" ] || { echo "FAIL: /usr/lib/gettoken/exchangers is writable by more than root"; exit 1; }
echo "ok: /usr/lib/gettoken/exchangers belongs to root and nobody else may write it"

echo
echo "# the human puts the super-token in the store, working on the privileged side"
printf '%s' "$super_token" | PATH="/usr/lib/gettoken:$PATH" secret-put '{"holder":"host-privileged","service":"integrationtest","version":1}'
[ -f "$store/host-privileged/integrationtest/1" ] || { echo "FAIL: the store is not $store"; exit 1; }
echo "ok: the store is $store"

echo
echo "# gettoken --list"
list=$(gettoken --list)
echo "$list"
[ "$list" = "$capability" ] || { echo "FAIL: unexpected capability list"; exit 1; }

echo
echo "# gettoken $capability"
out=$(gettoken "$capability")
echo "$out"
[ "$out" = "$narrow_token" ] || { echo "FAIL: gettoken did not return the downgraded token alone"; exit 1; }

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
echo "# purging takes the packages away, and the store with them"
apt-get purge -y gettoken gettoken-token-service gettoken-entitlements \
  gettoken-secret-manager gettoken-contract integration-test-tool \
  integration-test-tool-gettoken
apt-get autoremove --purge -y
for path in /usr/bin/gettoken /usr/lib/gettoken /usr/share/gettoken /var/lib/gettoken; do
  [ ! -e "$path" ] || { echo "FAIL: purging left $path behind"; exit 1; }
done
for needed in $runtime; do
  ! installed "$needed" \
    || { echo "FAIL: purging left $needed behind, which this base carried only because a package asked for it"; exit 1; }
done
echo "ok: nothing is left behind, down to what the packages drew in"

echo
echo "PASS: the packages carry the chain"
