#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "publish.sh fails when parameters are missing" {
  run bash "$root/scripts/publish.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "publish.sh: name the archive to publish" ]]
}
