#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  export PATH="$root/build/bin:$PATH"
  export CONTRACTS_DIR="$root/src/contracts"
  tmp_dir=$(mktemp -d)
}

teardown() {
  rm -rf "$tmp_dir"
}

@test "secret-get script fails when key is missing in store" {
  export SECRET_DIR="$tmp_dir"
  run "$root/src/components/secret-manager/secret-get" --with-key <<< '{"key":"nonexistent"}'
  [ "$status" -ne 0 ]
}
