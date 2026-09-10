#!/bin/bash
set -euo pipefail

packages=$1

apt-get update
apt-get install -y --no-install-recommends apt-utils

echo "deb [trusted=yes] file:$packages ./" > /etc/apt/sources.list.d/gettoken.list

echo "# 1. apt-get update as the verification runs it today"
apt-get update > /tmp/today.log 2>&1 && echo "exit=0" || echo "exit=$?"
echo "Err and Read-error lines: $(grep -cE '^Err|Read error' /tmp/today.log)"
grep -E '^(Ign|Err)|Read error|Symlinking file' /tmp/today.log | sed 's/^/  /'

echo
echo "# 2. the same, under the strictest error mode apt offers"
rm -rf /var/lib/apt/lists/*
apt-get update -o APT::Update::Error-Mode=any > /tmp/strict.log 2>&1 && echo "exit=0" || echo "exit=$?"

echo
echo "# 3. what apt does when the index is genuinely unreadable"
rm -rf /var/lib/apt/lists/*
cp "$packages/Packages" /tmp/Packages.bak
cp "$packages/Packages.gz" /tmp/Packages.gz.bak
printf 'this is not a package index\n' > "$packages/Packages"
printf 'this is not gzip\n' > "$packages/Packages.gz"
apt-get update > /tmp/broken.log 2>&1 && echo "exit=0" || echo "exit=$?"
cp /tmp/Packages.bak "$packages/Packages"
cp /tmp/Packages.gz.bak "$packages/Packages.gz"

echo
echo "# 4. the same archive with a Release file beside the index"
cp -a "$packages" /tmp/archive
cd /tmp/archive
apt-ftparchive release . > /tmp/Release
mv /tmp/Release Release
rm -rf /var/lib/apt/lists/*
echo "deb [trusted=yes] file:/tmp/archive ./" > /etc/apt/sources.list.d/gettoken.list
apt-get update > /tmp/release.log 2>&1 && echo "exit=0" || echo "exit=$?"
echo "Err and Read-error lines: $(grep -cE '^Err|Read error' /tmp/release.log)"
echo "Symlinking warnings: $(grep -c 'Symlinking file' /tmp/release.log)"
grep -E '^(Ign|Get|Err)' /tmp/release.log | sed 's/^/  /'

echo
echo "# 5. and the tool still resolves to the whole chain"
apt-get install -y --no-install-recommends -s integration-test-tool > /tmp/resolve.log 2>&1
echo "packages it would install: $(grep -c '^Inst ' /tmp/resolve.log)"
