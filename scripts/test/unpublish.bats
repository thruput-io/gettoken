#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "unpublish.sh prints usage error when branch argument is missing" {
  run bash "$root/scripts/unpublish.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "unpublish.sh: name the branch whose suite is being removed" ]]
}
