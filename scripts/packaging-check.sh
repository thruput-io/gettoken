#!/bin/bash
set -euo pipefail

packages=$1
tool=integration-test-tool

# shellcheck source=scripts/archive.sh
. "$(CDPATH='' cd "$(dirname "$0")/.." && pwd)/scripts/archive.sh"

apt_takes_the_archive_or_stops "$packages"
apt-get install -y --no-install-recommends "$tool"

apt-get purge -y "$tool"
apt-get autoremove --purge -y

dpkg_recorded() {
  awk -v action="$1" '$3 == action { print $4 }' /var/log/dpkg.log | sort -u
}

left_installed=$(comm -23 <(dpkg_recorded install) <(dpkg_recorded remove))
still_registered=$(dpkg-query -W -f='${Package} ${Status}\n' \
  | awk '/^gettoken|^integration-test-tool/ { print }')

echo "# what dpkg itself recorded"
dpkg_recorded install | sed 's/^/  dpkg installed /'
printf '%s' "$left_installed" | sed 's/^/  dpkg installed and never removed: /'
printf '%s' "$still_registered" | sed 's/^/  dpkg still registers: /'

test -z "$left_installed"
test -z "$still_registered"
echo "ok: dpkg removed every package it installed, and registers none of them now"

for path in /usr/bin/gettoken /usr/lib/gettoken /usr/share/gettoken /var/lib/gettoken; do
  [ ! -e "$path" ] || { echo "packaging-check: purging left $path behind" >&2; exit 1; }
done
echo "ok: purging the one package took the chain and the store with it"

mkdir -p /var/lib/gettoken/other
said=$(mktemp)
/work/debian/gettoken-secret-manager.postrm purge 2>"$said"
cat "$said"
grep -q '^gettoken-secret-manager: /var/lib/gettoken holds something' "$said" \
  || { echo "packaging-check: the purge did not say what it left behind" >&2; exit 1; }
[ -d /var/lib/gettoken/other ] \
  || { echo "packaging-check: the purge took a directory this package does not own" >&2; exit 1; }
echo "ok: a purge reports what it cannot remove rather than failing"
