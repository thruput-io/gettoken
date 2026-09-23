#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "package-brew.sh prints error when destination argument is missing" {
  run bash "$root/scripts/package-brew.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "package-brew.sh: name a directory to deliver the formula into" ]]
}
