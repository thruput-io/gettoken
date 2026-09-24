#!/usr/bin/env bash
set -euo pipefail

outdir=${1:?fetch-semgrep-bash.sh: name the directory to install into}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl --fail --silent --show-error --location \
  https://github.com/thruput-io/semgrep/archive/refs/heads/main.tar.gz | tar -xz -C "$work"

mkdir -p "$outdir/bin"
cp "$work"/semgrep-*/bash/bin/semgrep-bash "$outdir/bin/semgrep-bash"
chmod 755 "$outdir/bin/semgrep-bash"

rm -rf "$outdir/rules"
cp -r "$work"/semgrep-*/bash/rules "$outdir/rules"

echo "semgrep-bash and $(find "$outdir/rules" -name '*.yaml' | wc -l | tr -d ' ') rules installed into $outdir"
