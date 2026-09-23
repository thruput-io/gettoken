#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "check-branching passes when branching sites do not exceed thresholds" {
  run bash "$root/scripts/check-branching.sh" "$root" "$root/thresholds.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "no-branching:" ]]
}
