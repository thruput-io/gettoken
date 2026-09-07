bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH= cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/components/contract:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

@test "a document satisfying its contract is accepted" {
  run --separate-stderr sh -c 'printf %s "{\"holder\":\"johans-laptop\",\"service\":\"github\",\"version\":1}" | validate secret-put-request.schema.json'
  [ "$status" -eq 0 ]
}

@test "a document missing a required field is refused" {
  run -1 --separate-stderr sh -c 'printf %s "{\"holder\":\"johans-laptop\"}" | validate secret-put-request.schema.json'
}

@test "a field breaking its type is refused" {
  run -1 --separate-stderr sh -c 'printf %s "{\"holder\":\"johans-laptop\",\"service\":\"GitHub\",\"version\":1}" | validate secret-put-request.schema.json'
}

@test "a version that is not a positive integer is refused" {
  run -1 --separate-stderr sh -c 'printf %s "{\"holder\":\"johans-laptop\",\"service\":\"github\",\"version\":0}" | validate secret-put-request.schema.json'
}

@test "naming a contract that does not exist is refused" {
  run -1 --separate-stderr sh -c 'printf %s "{}" | validate no-such-contract.schema.json'
}

@test "the reason is on stderr and stdout stays empty" {
  run -1 --separate-stderr sh -c 'printf %s "{}" | validate secret-put-request.schema.json'
  [ "$output" = "" ]
  [ -n "$stderr" ]
}
