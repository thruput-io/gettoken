bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

admits() { printf '%s' "$2" | parse "$1"; }

@test "an ask naming a capability is admitted" {
  run -0 --separate-stderr admits agent-capability-request.schema.json '{"wants":"integrationtest/ci/run"}'
  [ "$stderr" = "" ]
}

@test "an ask for the list is admitted" {
  run -0 --separate-stderr admits agent-list-request.schema.json '{"query":"list"}'
  [ "$stderr" = "" ]
}

@test "an ask that is neither is refused" {
  run -1 --separate-stderr admits agent-capability-request.schema.json '{}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy agent-capability-request.schema.json"* ]]
}

@test "an ask that is both at once is refused" {
  run -1 --separate-stderr admits agent-capability-request.schema.json \
    '{"wants":"integrationtest/ci/run","query":"list"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy agent-capability-request.schema.json"* ]]
}

@test "an ask querying anything but the list is refused" {
  run -1 --separate-stderr admits agent-list-request.schema.json '{"query":"everything"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy agent-list-request.schema.json"* ]]
}

@test "an ask carrying a field the agent has no say over is refused" {
  run -1 --separate-stderr admits agent-capability-request.schema.json \
    '{"wants":"integrationtest/ci/run","signed":"forged-by-agent"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy agent-capability-request.schema.json"* ]]
}

@test "an ask whose capability is not one is refused" {
  run -1 --separate-stderr admits agent-capability-request.schema.json '{"wants":"../../bin/sh"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy agent-capability-request.schema.json"* ]]
}
