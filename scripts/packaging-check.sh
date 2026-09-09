#!/bin/sh
set -eu

packages=$1
tool=integration-test-tool

echo "deb [trusted=yes] file:$packages ./" > /etc/apt/sources.list.d/gettoken.list
apt-get update

present() {
  dpkg-query -W -f='${binary:Package} ${db:Status-Status}\n' | sed -n 's/ installed$//p' | sort
}

before=$(mktemp)
after=$(mktemp)
present > "$before"
apt-get install -y --no-install-recommends "$tool"
present > "$after"

arrived=$(comm -13 "$before" "$after")
for one in $arrived; do
  case $one in
    gettoken|gettoken-*|"$tool"|"$tool"-*) ;;
    *) echo "packaging-check: asking for $tool also brought in $one, which is not part of the chain" >&2; exit 1 ;;
  esac
done
echo "ok: asking for $tool brought in the chain and nothing else"

apt-mark showmanual | grep -qx "$tool" \
  || { echo "packaging-check: $tool is not the package that was asked for" >&2; exit 1; }
auto=$(apt-mark showauto)
for one in $arrived; do
  [ "$one" = "$tool" ] && continue
  printf '%s\n' "$auto" | grep -qx "$one" \
    || { echo "packaging-check: $one was not drawn in as a dependency" >&2; exit 1; }
done
echo "ok: the chain arrived because the packages declare it, not because it was asked for"

apt-get purge -y "$tool"
apt-get autoremove --purge -y

for path in /usr/bin/gettoken /usr/lib/gettoken /usr/share/gettoken /var/lib/gettoken; do
  [ ! -e "$path" ] || { echo "packaging-check: purging left $path behind" >&2; exit 1; }
done
echo "ok: purging the one package took the chain and the store with it"

mkdir -p /var/lib/gettoken/other
said=$(mktemp)
sh /work/debian/gettoken-secret-manager.postrm purge 2>"$said"
cat "$said"
grep -q '^gettoken-secret-manager: /var/lib/gettoken holds something' "$said" \
  || { echo "packaging-check: the purge did not say what it left behind" >&2; exit 1; }
[ -d /var/lib/gettoken/other ] \
  || { echo "packaging-check: the purge took a directory this package does not own" >&2; exit 1; }
echo "ok: a purge reports what it cannot remove rather than failing"
