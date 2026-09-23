#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "mermaid.sh validates README mermaid diagrams" {
  command -v npx > /dev/null || skip "npx not available"
  run bash "$root/scripts/mermaid.sh"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "PASS:" ]]
}
