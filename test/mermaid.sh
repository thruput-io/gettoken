#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
mermaid_cli="@mermaid-js/mermaid-cli@11.17.0"
work=$(mktemp -d)

block_count=$(awk -v outdir="$work" '
  /^```mermaid$/ { count++; file = sprintf("%s/block-%02d.mmd", outdir, count); inside=1; next }
  inside && /^```$/ { close(file); inside=0; next }
  inside { print > file }
  END { if (inside) exit 1; print count+0 }
' "$root/README.md")

echo "# $block_count mermaid block(s) extracted from README.md"
[ "$block_count" -gt 0 ] || { echo "FAIL: README.md contains no mermaid blocks"; exit 1; }

for block in "$work"/block-*.mmd; do
  name=$(basename "$block")
  npx -y "$mermaid_cli" -i "$block" -o "$block.svg" > "$block.log" 2>&1 \
    || { echo "FAIL: $name did not render"; cat "$block.log"; exit 1; }
  echo "ok: $name renders"
done

echo
echo "# the check must be able to fail"
invalid="$root/test/fixtures/invalid-diagram.mmd"
if npx -y "$mermaid_cli" -i "$invalid" -o "$work/invalid.svg" > "$work/invalid.log" 2>&1; then
  echo "FAIL: invalid-diagram.mmd rendered, so a broken diagram would pass unnoticed"
  exit 1
fi
echo "ok: invalid-diagram.mmd rejected"

rm -rf "$work"
echo
echo "PASS: every mermaid block in README.md renders"
