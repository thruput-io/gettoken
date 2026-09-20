bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  stub=$(mktemp -d)
  ASK_FILE="$stub/ask.json"
  ARGS_FILE="$stub/args"
  PATH="$stub:$root/src/tools/gettoken/bin:$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR ASK_FILE ARGS_FILE
}

teardown() { rm -rf "$stub"; }

capturing() {
  cat > "$stub/token-requester" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$ARGS_FILE"
for ask; do :; done
printf '%s' "$ask" > "$ASK_FILE"
printf 'stub-token\n'
STUB
  cat > "$stub/entitlements-requester" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" > "$ARGS_FILE"
for ask; do :; done
printf '%s' "$ask" > "$ASK_FILE"
printf 'stub-list\n'
STUB
  chmod 755 "$stub/token-requester" "$stub/entitlements-requester"
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

@test "a file to write to, with nothing asked for, refuses the same way" {
  run -1 --separate-stderr gettoken -f "$stub/token.txt"
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
  [ "$output" = "stub-list" ]
  [ "$(cat "$ASK_FILE")" = '{"query":"list"}' ]
}

@test "where the token is to be written is handed to the privileged half, not acted on here" {
  capturing
  run -0 --separate-stderr gettoken -f "$stub/token.txt" integrationtest/ci/run
  [ "$(head -2 "$ARGS_FILE")" = "$(printf '%s\n' -f "$stub/token.txt")" ]
  [ "$(cat "$ASK_FILE")" = '{"wants":"integrationtest/ci/run"}' ]
}

@test "a file is as much the list's to be written to as the token's" {
  capturing
  run -0 --separate-stderr gettoken -f "$stub/list.json" --list
  [ "$(head -2 "$ARGS_FILE")" = "$(printf '%s\n' -f "$stub/list.json")" ]
  [ "$(cat "$ASK_FILE")" = '{"query":"list"}' ]
}

@test "where the file is named makes no difference to what is asked for" {
  capturing
  run -0 --separate-stderr gettoken integrationtest/ci/run -f "$stub/token.txt"
  [ "$(head -2 "$ARGS_FILE")" = "$(printf '%s\n' -f "$stub/token.txt")" ]
  [ "$(cat "$ASK_FILE")" = '{"wants":"integrationtest/ci/run"}' ]
}
