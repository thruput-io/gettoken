#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "lint.sh executes shellcheck on codebase" {
  run bash "$root/scripts/lint.sh" "$root" "--format=checkstyle"
  [ "$status" -eq 0 ]
}
