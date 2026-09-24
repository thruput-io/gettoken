#!/usr/bin/env bash
set -euo pipefail

packages=${1:?archive.sh: name the directory holding the packages}
root=${2:?archive.sh: name the directory to build the archive in}
suite=${3:?archive.sh: name the suite, which is the branch the packages were built on}
key=${4:?archive.sh: name the key the archive signs with}

arch=$(dpkg --print-architecture)

home=$(mktemp -d)
conf=$(mktemp -d)
db=$(mktemp -d)
trap 'rm -rf "$home" "$conf" "$db"' EXIT
chmod 700 "$home"

gpg --homedir "$home" --batch --quiet --import "$key"
fingerprint=$(gpg --homedir "$home" --list-secret-keys --with-colons | awk -F: '/^fpr/ { print $10; exit }')

mkdir -p "$root"
root=$(CDPATH='' cd "$root" && pwd)
packages=$(CDPATH='' cd "$packages" && pwd)

rm -rf "${root:?}/pool/$suite" "${root:?}/dists/$suite"

gpg --homedir "$home" --batch --quiet --armor --export > "$root/gettoken-archive-keyring.asc"

cat > "$conf/distributions" <<DISTRIBUTION
Origin: gettoken
Label: gettoken
Codename: $suite
Suite: $suite
Architectures: $arch
Components: $suite
Description: token broker for AI agents
SignWith: $fingerprint
DISTRIBUTION

GNUPGHOME=$home reprepro --basedir "$root" --confdir "$conf" --dbdir "$db" --outdir "$root" \
  includedeb "$suite" "$packages"/*.deb

echo "$(find "$root/pool/$suite" -name '*.deb' | wc -l | tr -d ' ') $arch packages in $suite, indexed and signed"
