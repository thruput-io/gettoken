#!/usr/bin/env bash
set -euo pipefail

dist=${1:?clean-machine.sh: name the directory the packages were delivered into}

ROOT_DIR=$(CDPATH='' cd "$(dirname "$0")/../.." && pwd)
export ROOT_DIR

# shellcheck source-path=SCRIPTDIR/../..
# shellcheck source=dynamic.sh
source "$ROOT_DIR/dynamic.sh" > /dev/null
bash "$ROOT_DIR/src/integration-test/test.sh" "$dist"
