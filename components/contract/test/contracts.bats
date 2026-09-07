bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

admits() { printf '%s' "$2" | parse "$1"; }

requesting() {
  jq -nc --arg signed "$1" \
    '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}'
}

@test "a secret-get response claiming to be found without a value is refused" {
  run -1 --separate-stderr admits secret-get-response.schema.json '{"found":true,"version":1}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-response.schema.json"* ]]
}

@test "a secret-get response claiming not to be found while carrying a value is refused" {
  run -1 --separate-stderr admits secret-get-response.schema.json '{"found":false,"version":1,"value":"leaked"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-response.schema.json"* ]]
}

@test "a request whose signature is ordinary text is admitted" {
  run -0 --separate-stderr admits request.schema.json "$(requesting host-privileged)"
  [ "$stderr" = "" ]
}

@test "a request whose signature carries a control character is refused" {
  run -1 --separate-stderr admits request.schema.json "$(requesting "host$(printf '\001')privileged")"
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy request.schema.json"* ]]
}

@test "a request whose signature carries a delete character is refused" {
  run -1 --separate-stderr admits request.schema.json "$(requesting "host$(printf '\177')privileged")"
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy request.schema.json"* ]]
}

@test "a request whose signature ends in a newline is refused" {
  run -1 --separate-stderr admits request.schema.json \
    "$(jq -nc '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:"host-privileged\n"}')"
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy request.schema.json"* ]]
}

@test "a capability ending in a newline is refused" {
  run -1 --separate-stderr admits request.schema.json \
    "$(jq -nc '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run\n",signed:"host-privileged"}')"
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy request.schema.json"* ]]
}

@test "an agent name ending in a newline is refused" {
  run -1 --separate-stderr admits request.schema.json \
    "$(jq -nc '{who:"tore\n",doing:"mac.lan",wants:"integrationtest/ci/run",signed:"host-privileged"}')"
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy request.schema.json"* ]]
}

@test "a document the contract does not govern is refused, and says so differently" {
  run -1 --separate-stderr admits nosuch.schema.json '{}'
  [ "$output" = "" ]
  [[ "$stderr" == *"no contract named nosuch.schema.json"* ]]
}

@test "the validator implements the dialect the contracts declare" {
  probe=$(mktemp -d)
  cp "$root/contracts"/*.schema.json "$probe"
  jq -n '{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://thruput.io/gettoken/dialect.schema.json",
    type: "object",
    dependentRequired: { paid: ["method"] }
  }' > "$probe/dialect.schema.json"
  CONTRACTS_DIR="$probe"
  run -1 --separate-stderr admits dialect.schema.json '{"paid":true}'
  rm -rf "$probe"
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy dialect.schema.json"* ]]
}

@test "the first version and the last one the store can hold are both admitted" {
  run -0 --separate-stderr admits secret-get-request.schema.json '{"key":"johans-laptop/github","version":0}'
  [ "$stderr" = "" ]
  run -0 --separate-stderr admits secret-get-request.schema.json '{"key":"johans-laptop/github","version":1000000}'
  [ "$stderr" = "" ]
}

@test "a version before the first one the store can hold is refused" {
  run -1 --separate-stderr admits secret-get-request.schema.json '{"key":"johans-laptop/github","version":-1}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-request.schema.json"* ]]
}

@test "a version past the last one the store can hold is refused" {
  run -1 --separate-stderr admits secret-get-request.schema.json '{"key":"johans-laptop/github","version":1000001}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-request.schema.json"* ]]
}

@test "a minute and a day are both admitted as lifetimes" {
  run -0 --separate-stderr admits response.schema.json '{"access_token":"narrow","expires_in":60}'
  [ "$stderr" = "" ]
  run -0 --separate-stderr admits response.schema.json '{"access_token":"narrow","expires_in":86400}'
  [ "$stderr" = "" ]
}

@test "a lifetime shorter than a minute is refused" {
  run -1 --separate-stderr admits response.schema.json '{"access_token":"narrow","expires_in":59}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy response.schema.json"* ]]
}

@test "a lifetime longer than a day is refused" {
  run -1 --separate-stderr admits response.schema.json '{"access_token":"narrow","expires_in":86401}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy response.schema.json"* ]]
}

@test "a response carrying a field the contract does not govern is refused" {
  run -1 --separate-stderr admits response.schema.json \
    '{"access_token":"narrow","expires_in":120,"wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy response.schema.json"* ]]
}

@test "an ask naming a capability is admitted" {
  run -0 --separate-stderr admits ask.schema.json '{"wants":"integrationtest/ci/run"}'
  [ "$stderr" = "" ]
}

@test "an ask naming no capability is refused" {
  run -1 --separate-stderr admits ask.schema.json '{}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy ask.schema.json"* ]]
}

@test "an ask carrying a field the agent has no say over is refused" {
  run -1 --separate-stderr admits ask.schema.json \
    '{"wants":"integrationtest/ci/run","signed":"forged-by-agent"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy ask.schema.json"* ]]
}

@test "an ask whose capability is not one is refused" {
  run -1 --separate-stderr admits ask.schema.json '{"wants":"../../bin/sh"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy ask.schema.json"* ]]
}

@test "an exchange request naming who is asking and what for is admitted" {
  run -0 --separate-stderr admits exchange-request.schema.json \
    '{"who":"tore","wants":"integrationtest/ci/run"}'
  [ "$stderr" = "" ]
}

@test "an exchange request naming no agent is refused" {
  run -1 --separate-stderr admits exchange-request.schema.json '{"wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy exchange-request.schema.json"* ]]
}

@test "an exchange request does not carry the signature the request was signed with" {
  run -1 --separate-stderr admits exchange-request.schema.json \
    '{"who":"tore","wants":"integrationtest/ci/run","signed":"host-privileged"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy exchange-request.schema.json"* ]]
}

@test "an exchange request does not carry what the agent was doing" {
  run -1 --separate-stderr admits exchange-request.schema.json \
    '{"who":"tore","wants":"integrationtest/ci/run","doing":"mac.lan"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy exchange-request.schema.json"* ]]
}

@test "entitlements naming what they are and what their variables mean are admitted" {
  run -0 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"github/{org}/{repo}/pr/create","description":"Open a pull request.","variables":[{"name":"org","description":"The organisation that owns the repository."},{"name":"repo","description":"The repository to open the pull request against."}]}]}'
  [ "$stderr" = "" ]
}

@test "an entitlement that does not say what it is for is refused" {
  run -1 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"integrationtest/ci/run","variables":[]}]}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy entitlements-response.schema.json"* ]]
}

@test "an entitlement that leaves its variables unlisted is refused" {
  run -1 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"github/{org}/{repo}/pr/create","description":"Open a pull request."}]}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy entitlements-response.schema.json"* ]]
}

@test "a variable that is not named and explained is refused" {
  run -1 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"github/{org}/{repo}/pr/create","description":"Open a pull request.","variables":[{"name":"org"}]}]}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy entitlements-response.schema.json"* ]]
}

@test "an entitlements request carries no capability, because none is being asked for" {
  run -1 --separate-stderr admits entitlements-request.schema.json \
    '{"who":"tore","doing":"mac.lan","signed":"host-privileged","wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy entitlements-request.schema.json"* ]]
}
