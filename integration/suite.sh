#!/bin/sh
set -eu

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)

grep -rl '^#!/bin/sh' --exclude-dir=.git "$root" | xargs shellcheck -s sh -x

bin=${GETTOKEN_BIN:-$(mktemp -d)}
(cd "$root/components/contract" \
  && go build -mod=vendor -o "$bin/parse" ./cmd/parse \
  && go build -mod=vendor -o "$bin/format" ./cmd/format)
PATH="$bin:$PATH"
export PATH

bats --recursive "$root/components" "$root/tools"
sh "$root/tools/integration-test-tool/test/exit-status.sh"
sh "$root/integration/integration.sh"
