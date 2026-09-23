#!/usr/bin/env bash
set -euo pipefail

outdir=${1:?fetch-semgrep-bash.sh: name the directory to install into}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

if ! command -v semgrep > /dev/null; then
  if command -v pip > /dev/null; then
    pip install --break-system-packages --ignore-installed semgrep
  elif command -v pip3 > /dev/null; then
    pip3 install --break-system-packages --ignore-installed semgrep
  fi
fi

curl -sL https://github.com/thruput-io/semgrep/archive/refs/heads/main.tar.gz | tar -xz -C "$work"

mkdir -p "$outdir/bin"
cp "$work"/semgrep-*/bash/bin/semgrep-bash "$outdir/bin/semgrep-bash"
chmod 755 "$outdir/bin/semgrep-bash"

rm -rf "$outdir/rules"
cp -r "$work"/semgrep-*/bash/rules "$outdir/rules"
