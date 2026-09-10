bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  stub=$(mktemp -d)
  ASK_FILE="$stub/ask.json"
  PATH="$stub:$root/tools/gettoken/bin:$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR ASK_FILE
}

teardown() { rm -rf "$stub"; }

capturing() {
  cat > "$stub/token-requester" <<'STUB'
#!/bin/sh
cat > "$ASK_FILE"
printf 'stub-token\n'
STUB
  chmod 755 "$stub/token-requester"
}

@test "no arguments refuses, hands over nothing, and names the tool the agent invoked" {
  run -1 --separate-stderr gettoken
  [ "$output" = "" ]
  [[ "$stderr" == gettoken:* ]]
}

@test "more than one argument refuses the same way" {
  run -1 --separate-stderr gettoken integrationtest/ci/run and-another
  [ "$output" = "" ]
  [[ "$stderr" == gettoken:* ]]
}

@test "the ask names the capability and nothing the agent has no say over" {
  capturing
  run -0 --separate-stderr gettoken integrationtest/ci/run
  [ "$output" = "stub-token" ]
  [ "$(cat "$ASK_FILE")" = '{"wants":"integrationtest/ci/run"}' ]
}

@test "the ask for the list says it is the list being asked for" {
  capturing
  run -0 --separate-stderr gettoken --list
  [ "$(cat "$ASK_FILE")" = '{"query":"list"}' ]
}
