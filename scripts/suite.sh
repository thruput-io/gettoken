#!/bin/sh
set -eu

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
bin="$root/build/bin"

sh "$root/scripts/lint.sh" "$root"
sh "$root/scripts/readme.sh" "$root"

sh "$root/components/contract/build.sh" "$bin"

PATH="$bin:$PATH"
export PATH

bats --recursive "$root/components" "$root/tools" "$root/scripts"
