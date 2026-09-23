#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "pages.sh defines page variables" {
  run bash -c "source '$root/scripts/pages.sh' && echo \"\$pages_branch\""
  [ "$status" -eq 0 ]
  [ "$output" = "gh-pages" ]
}
