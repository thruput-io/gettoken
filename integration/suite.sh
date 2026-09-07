#!/bin/sh
set -eu

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
bin="$root/build/bin"

grep -rl '^#!/bin/sh' --exclude-dir=.git --exclude-dir=build "$root" | xargs shellcheck -s sh -x

sh "$root/components/contract/build.sh" "$bin"

PATH="$bin:$PATH"
export PATH

bats --recursive "$root/components" "$root/tools"
sh "$root/tools/integration-test-tool/test/exit-status.sh"
sh "$root/integration/integration.sh"
