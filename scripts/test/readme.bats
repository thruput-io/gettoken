#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "readme.sh validates README layout block against repository tree" {
  run bash "$root/scripts/readme.sh" "$root" "--check"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "ok: README.md says what the tree holds" ]]
}
