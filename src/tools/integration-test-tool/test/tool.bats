bats_require_minimum_version 1.5.0

load '../../../../scripts/test/helper'

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  PATH="$root/src/tools/integration-test-tool/bin:$PATH"
  export PATH
}

running() {
  INTEGRATIONTEST_TOKEN="$1" integration-test-tool
}

@test "the tool writes back what the narrow token carries, and nothing else" {
  run -0 --separate-stderr running sample-token-123-ci-run-allowed
  [ "$output" = "sample-token-123" ]
}

@test "the super-token that token was traded for is refused" {
  run -1 --separate-stderr running super-sample-token-123
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "integration-test-tool: INTEGRATIONTEST_TOKEN does not allow integrationtest/ci/run"
}

@test "no token at all is refused, and hands over nothing" {
  run -1 --separate-stderr sh -c 'unset INTEGRATIONTEST_TOKEN; integration-test-tool'
  [ "$output" = "" ]
}

@test "a token allowing something else is refused" {
  run -1 --separate-stderr running sample-token-123-ci-run-denied
  [ "$output" = "" ]
}

@test "a token carrying nothing but the suffix is refused" {
  run -1 --separate-stderr running -ci-run-allowed
  [ "$output" = "" ]
}

@test "a token that is nearly the right one is refused, because it is not it" {
  run -1 --separate-stderr running sample-token-123-ci-run-allowed-too
  [ "$output" = "" ]
}
