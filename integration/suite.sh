#!/bin/sh
set -eu

root=$(CDPATH= cd "$(dirname "$0")/.." && pwd)

sh "$root/tools/integration-test-tool/test/exit-status.sh"
sh "$root/integration/integration.sh"
