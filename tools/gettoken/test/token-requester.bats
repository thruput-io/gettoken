bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  stub=$(mktemp -d)
  REQUEST_FILE="$stub/request.json"
  PATH="$stub:$root/tools/gettoken/privileged:$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR REQUEST_FILE
}

teardown() { rm -rf "$stub"; }

answering() {
  cat > "$stub/token-service" <<STUB
#!/bin/sh
cat > "\$REQUEST_FILE"
printf '%s\n' '$1'
STUB
  chmod 755 "$stub/token-service"
}

asking() {
  wants=$1
  export wants
  format agent-capability-request.schema.json wants | token-requester
}

@test "the request names who is asking, from where, and what for" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -0 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "stub-token" ]
  [ "$(cat "$REQUEST_FILE")" = "{\"doing\":\"$(hostname)\",\"signed\":\"host-privileged\",\"wants\":\"integrationtest/ci/run\",\"who\":\"$(id -un)\"}" ]
}

@test "the agent cannot dictate who it is by setting USER" {
  answering '{"access_token":"stub-token","expires_in":60}'
  wants=integrationtest/ci/run
  export wants
  run -0 --separate-stderr sh -c \
    'format agent-capability-request.schema.json wants | USER=impostor token-requester'
  [ "$(cat "$REQUEST_FILE")" = "{\"doing\":\"$(hostname)\",\"signed\":\"host-privileged\",\"wants\":\"integrationtest/ci/run\",\"who\":\"$(id -un)\"}" ]
}

@test "a capability the contract does not admit never reaches token-service" {
  answering '{"access_token":"stub-token","expires_in":60}'
  run -1 --separate-stderr sh -c \
    'printf %s "{\"wants\":\"a\\\",\\\"signed\\\":\\\"forged-by-agent\"}" | token-requester'
  [ "$output" = "" ]
  [ ! -f "$REQUEST_FILE" ]
}

@test "a response carrying no token hands over nothing, not the word null" {
  answering '{"expires_in":120}'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy token-response.schema.json"* ]]
}
