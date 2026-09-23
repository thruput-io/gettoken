#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  export PATH="$root/build/bin:$PATH"
  export CONTRACTS_DIR="$root/src/contracts"
}

@test "token-service fails on invalid json request" {
  run "$root/src/components/token-service/token-service" <<< 'invalid-json'
  [ "$status" -ne 0 ]
}
