#!/bin/sh
set -eu

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
. "$root/integration/chain.sh"

[ "${GETTOKEN_DISPOSABLE_BASE:-}" = yes ] || {
  echo "packages.sh: this run installs and purges packages and deletes the secret"
  echo "store, so it refuses to touch a machine. It is meant for the throwaway base"
  echo "make debian-packages builds, which sets GETTOKEN_DISPOSABLE_BASE=yes."
  exit 1
}

capability=integrationtest/ci/run
integration='integration-test-tool'
drawn_in="gettoken gettoken-token-service gettoken-entitlements gettoken-secret-manager gettoken-parse gettoken-format gettoken-contract-defs gettoken-contract-agent-capability-request gettoken-contract-agent-list-request gettoken-contract-entitlements-request gettoken-contract-entitlements-response gettoken-contract-exchange-request gettoken-contract-secret-get-request gettoken-contract-secret-get-request-version gettoken-contract-secret-get-response gettoken-contract-secret-put-request gettoken-contract-secret-put-response gettoken-contract-token-request gettoken-contract-token-response"
super_token=integrationtest-supertoken
narrow_token=integrationtest-ci-run-allowed
store=/var/lib/gettoken/secrets

build=$(mktemp -d)
source_list=/etc/apt/sources.list.d/gettoken-build.list
trap 'rm -rf "$build" "$source_list"' EXIT

states=$(mktemp)
installed() {
  dpkg-query -W -f='${binary:Package} ${db:Status-Status}\n' > "$states" \
    || { echo "FAIL: dpkg-query could not list package states, so nothing below can be believed"; exit 1; }
  grep -qx "$1 installed" "$states"
}

echo "# every shell file this tree carries passes the lint gate, including the"
echo "# maintainer scripts, which only this lane installs the packaging for"
sh "$root/integration/lint.sh" "$root"

echo
echo "# the packages are built from the source tree"
cp -a "$root" "$build/source"
rm -rf "$build/source/.git"
(cd "$build/source" && dpkg-buildpackage -us -uc)
ls "$build"/*.deb

echo
echo "# lintian passes on the source and on every package, and a warning is"
echo "# enough to fail: at its defaults only an error is, so a warning about a"
echo "# permission or an owner this run asserts by hand would pass unnoticed"
lintian --fail-on error,warning,info,pedantic,experimental --display-level '>=pedantic' "$build"/*.changes

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
for needed in $drawn_in; do
  ! installed "$needed" \
    || { echo "FAIL: $needed is already installed, so this run cannot show that apt draws it in"; exit 1; }
done
echo "ok: none of $drawn_in is installed"

echo
echo "# integrating a tool is installing that tool's package, and nothing else"
present() {
  dpkg-query -W -f='${binary:Package} ${db:Status-Status}\n' \
    | sed -n 's/ installed$//p' | sort
}
before="$build/before"
present > "$before"
apt-get install -y --no-install-recommends "$integration"

echo
echo "# the chain arrived because the packages declare it, not because it was asked for"
auto=$(apt-mark showauto)
for needed in $drawn_in; do
  installed "$needed" \
    || { echo "FAIL: apt did not install $needed, so some package does not declare it"; exit 1; }
  printf '%s\n' "$auto" | grep -qx "$needed" \
    || { echo "FAIL: $needed was not drawn in as a dependency"; exit 1; }
done
apt-mark showmanual | grep -qx "$integration" \
  || { echo "FAIL: $integration is not the package that was asked for"; exit 1; }
echo "ok: $integration was asked for; $drawn_in came with it"

echo
echo "# and nothing else came with it: the chain runs on its own packages alone"
present > "$build/after"
for one in $(comm -13 "$before" "$build/after"); do
  case " $drawn_in $integration " in
    *" $one "*) ;;
    *) echo "FAIL: installing $integration also brought in $one, which is not part of the chain"; exit 1 ;;
  esac
done
echo "ok: the chain runs on its own packages and brought in nothing else"

echo
echo "# the components put the agent's entry point on a public PATH and nothing else,"
echo "# and the tool puts the tool: its exchanger is not something an agent can run"
public=$(for one in $drawn_in; do dpkg-query -L "$one"; done | grep '^/usr/bin/' | sort)
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
key=host-privileged/integrationtest
value=$super_token
export key value
PATH="/usr/lib/gettoken:$PATH" format secret-put-request.schema.json key value \
  | PATH="/usr/lib/gettoken:$PATH" secret-put
[ -f "$store/host-privileged/integrationtest/0" ] || { echo "FAIL: the store is not $store"; exit 1; }
echo "ok: the store is $store"

chain_runs "$capability" "$super_token" "$narrow_token"

echo
echo "# purging takes the packages away, and the store with them"
apt-get purge -y "$integration"
apt-get autoremove --purge -y
for needed in $drawn_in; do
  ! installed "$needed" \
    || { echo "FAIL: purging $integration left $needed behind"; exit 1; }
done
for path in /usr/bin/gettoken /usr/lib/gettoken /usr/share/gettoken /var/lib/gettoken; do
  [ ! -e "$path" ] || { echo "FAIL: purging left $path behind"; exit 1; }
done
echo "ok: nothing is left behind, down to what the one package drew in"

echo
echo "# a purge that finds something under /var/lib/gettoken this package does not"
echo "# own says so and still succeeds: dpkg reporting a failed post-removal script"
echo "# would leave the package unpurged for an admin to repair by hand"
mkdir -p /var/lib/gettoken/other
purge_err=$(mktemp)
sh "$build/source/debian/gettoken-secret-manager.postrm" purge 2>"$purge_err"
cat "$purge_err"
grep -q '^gettoken-secret-manager: /var/lib/gettoken holds something' "$purge_err" \
  || { echo "FAIL: the purge did not say what it left behind"; exit 1; }
[ -d /var/lib/gettoken/other ] || { echo "FAIL: the purge took a directory this package does not own"; exit 1; }
rm -f "$purge_err"
rm -rf /var/lib/gettoken
echo "ok: a purge reports what it cannot remove rather than failing"

echo
echo "PASS: the packages carry the chain"
