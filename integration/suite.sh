#!/bin/sh
set -eu

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
bin="$root/build/bin"

sh "$root/integration/lint.sh" "$root"
sh "$root/integration/readme.sh" "$root"

sh "$root/components/contract/build.sh" "$bin"

PATH="$bin:$PATH"
export PATH

bats --recursive "$root/components" "$root/tools"
sh "$root/tools/integration-test-tool/test/exit-status.sh"
