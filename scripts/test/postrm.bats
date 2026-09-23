#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "postrm script exits cleanly on remove" {
  run bash "$root/src/debian/gettoken-secret-manager.postrm" "remove"
  [ "$status" -eq 0 ]
}
