#!/bin/bash
set -euo pipefail

if [ $# -ne 4 ]; then
  echo "usage: archive.sh PACKAGES ROOT SUITE SIGNING-KEY" >&2
  exit 1
fi
packages=$1
root=$2
suite=$3
key=$4

pool="pool/$suite"
dist="dists/$suite"

arch=$(dpkg --print-architecture)

release_anyone_can_read="$root/Release.building"
home=$(mktemp -d)
trap 'rm -f "$release_anyone_can_read"; rm -rf "$home"' EXIT
chmod 700 "$home"

gpg --homedir "$home" --batch --quiet --import "$key"

rm -rf "${root:?}/$pool" "${root:?}/$dist"
mkdir -p "$root/$pool" "$root/$dist/main/binary-$arch"
cp "$packages"/*.deb "$root/$pool"

gpg --homedir "$home" --batch --quiet --armor --export > "$root/gettoken-archive-keyring.asc"

cd "$root"

apt-ftparchive packages "$pool" > "$dist/main/binary-$arch/Packages"
gzip -kf "$dist/main/binary-$arch/Packages"

apt-ftparchive \
  -o "APT::FTPArchive::Release::Origin=gettoken" \
  -o "APT::FTPArchive::Release::Label=gettoken" \
  -o "APT::FTPArchive::Release::Suite=$suite" \
  -o "APT::FTPArchive::Release::Codename=$suite" \
  -o "APT::FTPArchive::Release::Architectures=$arch" \
  -o "APT::FTPArchive::Release::Components=main" \
  -o "APT::FTPArchive::Release::Description=token broker for AI agents" \
  release "$dist" > "$release_anyone_can_read"
mv "$release_anyone_can_read" "$dist/Release"

gpg --homedir "$home" --batch --quiet --yes --pinentry-mode loopback --passphrase '' \
    --clearsign --output "$dist/InRelease" "$dist/Release"
gpg --homedir "$home" --batch --quiet --yes --pinentry-mode loopback --passphrase '' \
    --detach-sign --armor --output "$dist/Release.gpg" "$dist/Release"

echo "$(find "$pool" -name '*.deb' | wc -l) $arch packages in $suite, indexed and signed"
