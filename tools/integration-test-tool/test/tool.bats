bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/tools/integration-test-tool/bin:$PATH"
  export PATH
}

running() {
  INTEGRATIONTEST_TOKEN="$1" integration-test-tool
}

@test "the tool writes back what the narrow token carries, and nothing else" {
  run -0 --separate-stderr running 4f2a9c-ci-run-allowed
  [ "$output" = "4f2a9c" ]
}

@test "the super-token that token was traded for is refused" {
  run -1 --separate-stderr running super-4f2a9c
  [ "$output" = "" ]
  [ "$stderr" = "integration-test-tool: INTEGRATIONTEST_TOKEN does not allow integrationtest/ci/run" ]
}

@test "no token at all is refused, and hands over nothing" {
  run -1 --separate-stderr sh -c 'unset INTEGRATIONTEST_TOKEN; integration-test-tool'
  [ "$output" = "" ]
}

@test "a token allowing something else is refused" {
  run -1 --separate-stderr running 4f2a9c-ci-run-denied
  [ "$output" = "" ]
}

@test "a token carrying nothing but the suffix is refused" {
  run -1 --separate-stderr running -ci-run-allowed
  [ "$output" = "" ]
}
