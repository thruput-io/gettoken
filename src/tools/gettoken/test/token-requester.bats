bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  stub=$(mktemp -d)
  REQUEST_FILE="$stub/request.json"
  PATH="$stub:$root/src/tools/gettoken/privileged:$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR REQUEST_FILE
}

teardown() { rm -rf "$stub"; }

answering() {
  cat > "$stub/token-service" <<STUB
#!/bin/sh
printf '%s' "\$1" > "\$REQUEST_FILE"
printf '%s\n' '$1'
STUB
  chmod 755 "$stub/token-service"
}

asked() {
  wants=$1
  export wants
  format agent-capability-request.schema.json wants
}

asking() { token-requester "$(asked "$1")"; }

@test "the request names who is asking, from where, and what for" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -0 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "stub-token" ]
  [ "$(cat "$REQUEST_FILE")" = "{\"doing\":\"$(hostname)\",\"signed\":\"host-privileged\",\"wants\":\"integrationtest/ci/run\",\"who\":\"$(id -un)\"}" ]
}

@test "the agent cannot dictate who it is by setting USER" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -0 --separate-stderr env USER=impostor token-requester "$(asked integrationtest/ci/run)"
  [ "$(cat "$REQUEST_FILE")" = "{\"doing\":\"$(hostname)\",\"signed\":\"host-privileged\",\"wants\":\"integrationtest/ci/run\",\"who\":\"$(id -un)\"}" ]
}

@test "the ask is as good taken from standard input as given as an argument" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -0 --separate-stderr sh -c 'asked=$1; printf %s "$asked" | token-requester --stdin' sh "$(asked integrationtest/ci/run)"
  [ "$output" = "stub-token" ]
  [ "$(jq -r '.wants' < "$REQUEST_FILE")" = "integrationtest/ci/run" ]
}

@test "the token can be written to a file rather than handed back, and nothing else is written" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -0 --separate-stderr token-requester -f "$stub/token.txt" "$(asked integrationtest/ci/run)"
  [ "$output" = "" ]
  [ "$(cat "$stub/token.txt")" = "stub-token" ]
}

@test "a file the token was written to is closed to everyone but its owner" {
  answering '{"access_token":"stub-token","expires_in":60}'
  token-requester -f "$stub/token.txt" "$(asked integrationtest/ci/run)"
  run -0 --separate-stderr find "$stub/token.txt" -perm 600
  [ "$output" = "$stub/token.txt" ]
}

@test "how long the token lasts is not something the agent is told" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -0 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "stub-token" ]
}

@test "a capability the contract does not admit never reaches token-service" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -1 --separate-stderr token-requester '{"wants":"a\",\"signed\":\"forged-by-agent"}'
  [ "$output" = "" ]
  [ ! -f "$REQUEST_FILE" ]
}

@test "an ask for the list is not one this door takes" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -1 --separate-stderr token-requester '{"query":"list"}'
  [ "$output" = "" ]
  [ ! -f "$REQUEST_FILE" ]
}

@test "a response carrying no token hands over nothing, not the word null" {
  answering '{"expires_in":120}'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy token-response.schema.json"* ]]
}

@test "nothing asked for at all is refused with how to ask" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -1 --separate-stderr token-requester
  [ "$output" = "" ]
  [[ "$stderr" == "token-requester: usage:"* ]]
}
