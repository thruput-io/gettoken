#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "signing-key.sh prints error when keyfile argument is missing" {
  run bash "$root/scripts/signing-key.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "signing-key.sh: name the file to write the key to" ]]
}
