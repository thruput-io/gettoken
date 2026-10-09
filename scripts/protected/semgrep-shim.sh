#!/usr/bin/env bash
set -euo pipefail

outdir=${1:?semgrep-shim.sh: name the directory to install the shim into}

mkdir -p "$outdir/bin"
cat > "$outdir/bin/semgrep" <<'SHIM'
#!/bin/bash
set -euo pipefail
exec pipx run semgrep==1.176.0 "$@"
SHIM
chmod 755 "$outdir/bin/semgrep"

echo "semgrep shim installed into $outdir/bin, running semgrep 1.176.0 through pipx"
