#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "archive.sh prints error when arguments are missing" {
  run bash "$root/scripts/archive.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "archive.sh: name the directory holding the packages" ]]
}
