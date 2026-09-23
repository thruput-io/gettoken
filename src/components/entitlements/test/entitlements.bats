#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
  export PATH="$root/build/bin:$PATH"
  export CONTRACTS_DIR="$root/src/contracts"
}

@test "entitlements script produces entitlement output for valid request" {
  run "$root/src/components/entitlements/entitlements" <<< '{"who": "agent-1", "doing": "testing", "signed": "sig-1"}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "integrationtest/ci/run" ]]
}
