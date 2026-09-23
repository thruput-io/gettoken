#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "generate-key.sh prints error when keyfile parameter is missing" {
  run bash "$root/scripts/generate-key.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "generate-key.sh: name the file to write the key to" ]]
}
