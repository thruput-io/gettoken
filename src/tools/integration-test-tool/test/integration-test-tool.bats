#!/usr/bin/env bats

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/../../../.." && pwd)"
}

@test "integration-test-tool binary exists" {
  [ -f "$root/src/tools/integration-test-tool/bin/integration-test-tool" ]
}
