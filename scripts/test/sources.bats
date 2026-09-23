#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "sources.sh prints usage error when arguments are missing" {
  run bash "$root/scripts/sources.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "sources.sh: name the archive to write the sources file into" ]]
}
