#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "package-deb.sh prints error when destination argument is missing" {
  run bash "$root/scripts/package-deb.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "package-deb.sh: name a directory to deliver the packages into" ]]
}
