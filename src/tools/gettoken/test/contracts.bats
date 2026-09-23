bats_require_minimum_version 1.5.0

setup() {
  export BATS_LIB_PATH="/usr/lib/bats:/usr/lib:/opt/homebrew/lib:/usr/local/lib"
  bats_load_library bats-support
  bats_load_library bats-assert
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR
}

NormalizeStdErrWhenKcovOnMac() {
  printf '%s' "$1" | sed -E '/(k+cov@|^(wants|key|value|fields|asked)=)/d'
}

admits() { printf '%s' "$2" | parse "$1"; }

@test "an ask naming a capability is admitted" {
  run -0 --separate-stderr admits agent-capability-request.schema.json '{"wants":"integrationtest/ci/run"}'
  assert_equal "$(NormalizeStdErrWhenKcovOnMac "$stderr")" ""
}

@test "an ask for the list is admitted" {
  run -0 --separate-stderr admits agent-list-request.schema.json '{"query":"list"}'
  assert_equal "$(NormalizeStdErrWhenKcovOnMac "$stderr")" ""
}

@test "an ask that is neither is refused" {
  run -1 --separate-stderr admits agent-capability-request.schema.json '{}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy agent-capability-request.schema.json\nvalidating https://thruput.io/gettoken/ask-capability.schema.json: required: missing properties: ["wants"]')
  assert_equal "$(NormalizeStdErrWhenKcovOnMac "$stderr")" "$expected"
}

@test "an ask that is both at once is refused" {
  run -1 --separate-stderr admits agent-capability-request.schema.json \
    '{"wants":"integrationtest/ci/run","query":"list"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy agent-capability-request.schema.json\nvalidating https://thruput.io/gettoken/ask-capability.schema.json: unexpected additional properties ["query"]')
  assert_equal "$(NormalizeStdErrWhenKcovOnMac "$stderr")" "$expected"
}

@test "an ask querying anything but the list is refused" {
  run -1 --separate-stderr admits agent-list-request.schema.json '{"query":"everything"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy agent-list-request.schema.json\nvalidating https://thruput.io/gettoken/ask.schema.json: validating /properties/query: const: everything does not equal list')
  assert_equal "$(NormalizeStdErrWhenKcovOnMac "$stderr")" "$expected"
}

@test "an ask carrying a field the agent has no say over is refused" {
  run -1 --separate-stderr admits agent-capability-request.schema.json \
    '{"wants":"integrationtest/ci/run","signed":"forged-by-agent"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy agent-capability-request.schema.json\nvalidating https://thruput.io/gettoken/ask-capability.schema.json: unexpected additional properties ["signed"]')
  assert_equal "$(NormalizeStdErrWhenKcovOnMac "$stderr")" "$expected"
}

@test "an ask whose capability is not one is refused" {
  run -1 --separate-stderr admits agent-capability-request.schema.json '{"wants":"../../bin/sh"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy agent-capability-request.schema.json\nvalidating https://thruput.io/gettoken/ask-capability.schema.json: validating /properties/wants: validating /$defs/Capability: pattern: "../../bin/sh" does not match regular expression "^[a-z0-9-]+(/[a-z0-9._-]+)+$"')
  assert_equal "$(NormalizeStdErrWhenKcovOnMac "$stderr")" "$expected"
}
