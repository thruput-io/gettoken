#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "served.sh prints usage error when arguments are missing" {
  run bash "$root/scripts/served.sh"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "usage: served.sh ARCHIVE DOCKER-ARGUMENT..." ]]
}
