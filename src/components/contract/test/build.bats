#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
}

@test "contract build.sh usage check" {
  run bash "$root/src/components/contract/build.sh"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "usage: build.sh DIRECTORY" ]]
}
