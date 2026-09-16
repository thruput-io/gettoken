#!/bin/bash
set -euo pipefail

archive=$1

test -f "$archive/InRelease"

echo "TODO: publishing $archive to an archive is not implemented" >&2
exit 1
