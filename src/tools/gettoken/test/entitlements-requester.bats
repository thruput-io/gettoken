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

listing='{"entitlements":[{"capability":"integrationtest/ci/run","description":"Run it.","variables":[]}]}'

answering() {
  cat > "$stub/entitlements" <<STUB
#!/bin/sh
printf '%s' "\$1" > "\$REQUEST_FILE"
printf '%s\n' '$1'
STUB
  chmod 755 "$stub/entitlements"
}

asking() { entitlements-requester '{"query":"list"}'; }

@test "the request names who is asking and from where, and asks for no capability" {
  answering "$listing"
  run -0 --separate-stderr asking
  [ "$(cat "$REQUEST_FILE")" = "{\"doing\":\"$(hostname)\",\"signed\":\"host-privileged\",\"who\":\"$(id -un)\"}" ]
}

@test "what may be equipped is handed back whole, because it is the agent's to read" {
  answering "$listing"
  run -0 --separate-stderr asking
  [ "$(printf '%s' "$output" | jq -r '.entitlements[0].capability')" = "integrationtest/ci/run" ]
  [ "$stderr" = "" ]
}

@test "the list can be written to a file rather than handed back" {
  answering "$listing"
  run -0 --separate-stderr entitlements-requester -f "$stub/list.json" '{"query":"list"}'
  [ "$output" = "" ]
  [ "$(jq -r '.entitlements[0].capability' < "$stub/list.json")" = "integrationtest/ci/run" ]
}

@test "an ask naming a capability is not one this door takes" {
  answering "$listing"
  run -1 --separate-stderr entitlements-requester '{"wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  [ ! -f "$REQUEST_FILE" ]
}

@test "a list carrying a capability no pattern admits hands over nothing" {
  answering '{"entitlements":[{"capability":"Integrationtest/CI","description":"Run it.","variables":[]}]}'
  run -1 --separate-stderr asking
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy entitlements-response.schema.json"* ]]
}

@test "nothing asked for at all is refused with how to ask" {
  answering "$listing"
  run -1 --separate-stderr entitlements-requester
  [ "$output" = "" ]
  [[ "$stderr" == "entitlements-requester: usage:"* ]]
}
