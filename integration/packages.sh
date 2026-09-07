#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)

capability=integrationtest/ci/run
integration=integration-test-tool
drawn_in="gettoken gettoken-token-service gettoken-entitlements gettoken-secret-manager gettoken-contract"
runtime="jq libjson-schema-modern-perl libgetopt-long-descriptive-perl"
super_token=integrationtest-supertoken
narrow_token=integrationtest-ci-run-allowed
store=/var/lib/gettoken/secrets

build=$(mktemp -d)
source_list=/etc/apt/sources.list.d/gettoken-build.list
trap 'rm -rf "$build" "$source_list"' EXIT

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
echo "# the packages are put where apt can reach them by name, so nothing has to be"
echo "# installed by naming a file"
(cd "$build" && dpkg-scanpackages -m . > Packages)
chmod 755 "$build"
echo "deb [trusted=yes] file:$build ./" > "$source_list"
apt-get update

echo
echo "# nothing the chain runs on is on this base, so apt has to resolve every"
echo "# dependency the packages declare rather than find it already there"
for needed in $drawn_in $runtime; do
  ! installed "$needed" \
    || { echo "FAIL: $needed is already installed, so this run cannot show that apt draws it in"; exit 1; }
done
echo "ok: none of $drawn_in $runtime is installed"

echo
echo "# integrating a tool is installing that tool's package, and nothing else"
apt-get install -y --no-install-recommends "$integration"

echo
echo "# the chain arrived because the packages declare it, not because it was asked for"
auto=$(apt-mark showauto)
for needed in $drawn_in $runtime; do
  installed "$needed" \
    || { echo "FAIL: apt did not install $needed, so some package does not declare it"; exit 1; }
  printf '%s\n' "$auto" | grep -qx "$needed" \
    || { echo "FAIL: $needed was not drawn in as a dependency"; exit 1; }
done
apt-mark showmanual | grep -qx "$integration" \
  || { echo "FAIL: $integration is not the package that was asked for"; exit 1; }
echo "ok: $integration was asked for; $drawn_in $runtime came with it"

echo
echo "# the components put the agent's entry point on a public PATH and nothing else,"
echo "# and the tool puts the tool: its exchanger is not something an agent can run"
public=$(dpkg-query -L $drawn_in | grep '^/usr/bin/' | sort)
echo "$public"
[ "$public" = /usr/bin/gettoken ] || { echo "FAIL: the components put more than gettoken on a public PATH"; exit 1; }
tool_public=$(dpkg-query -L "$integration" | grep '^/usr/bin/' | sort)
echo "$tool_public"
[ "$tool_public" = "/usr/bin/$integration" ] || { echo "FAIL: $integration puts more than the tool on a public PATH"; exit 1; }

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
apt-get purge -y "$integration"
apt-get autoremove --purge -y
for needed in $drawn_in $runtime; do
  ! installed "$needed" \
    || { echo "FAIL: purging $integration left $needed behind"; exit 1; }
done
for path in /usr/bin/gettoken /usr/lib/gettoken /usr/share/gettoken /var/lib/gettoken; do
  [ ! -e "$path" ] || { echo "FAIL: purging left $path behind"; exit 1; }
done
echo "ok: nothing is left behind, down to what the one package drew in"

echo
echo "PASS: the packages carry the chain"
