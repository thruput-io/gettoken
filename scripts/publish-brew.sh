#!/bin/bash
set -euo pipefail

formula=$1

test -f "$formula"

echo "TODO: publishing $formula to a tap is not implemented" >&2
exit 1
