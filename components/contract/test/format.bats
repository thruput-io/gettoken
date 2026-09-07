bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

@test "a value that is not JSON is the one that gets quoted" {
  who=tore doing=mac.lan wants=integrationtest/ci/run signed=host-privileged
  export who doing wants signed
  document=$(format request.schema.json who doing wants signed)
  [ "$(printf '%s' "$document" | jq -r '.who | type')" = "string" ]
  [ "$(printf '%s' "$document" | jq -r '.wants | type')" = "string" ]
  [ "$(printf '%s' "$document" | jq -r '.who')" = "tore" ]
}

@test "a value that is a number goes in as a number" {
  access_token=narrow expires_in=120
  export access_token expires_in
  document=$(format response.schema.json access_token expires_in)
  [ "$(printf '%s' "$document" | jq -r '.expires_in | type')" = "number" ]
  [ "$(printf '%s' "$document" | jq -r '.access_token | type')" = "string" ]
}

@test "a secret reaches a document without passing a command line" {
  key=johans-laptop/github value=super-1
  export key value
  document=$(format secret-put-request.schema.json key value)
  [ "$(printf '%s' "$document" | jq -r '.value')" = "super-1" ]
}

@test "a value carrying what would break a document is written whole" {
  key=johans-laptop/github
  value='super "1" \ and
a second line'
  export key value
  document=$(format secret-put-request.schema.json key value)
  [ "$(printf '%s' "$document" | jq -r '.value')" = "$value" ]
}

@test "a field whose variable is not set is refused" {
  who=tore doing=mac.lan wants=integrationtest/ci/run
  export who doing wants
  unset signed
  run -1 --separate-stderr format request.schema.json who doing wants signed
  [ "$output" = "" ]
  [[ "$stderr" == *"signed is not set"* ]]
}

@test "a field named twice is refused" {
  who=tore doing=mac.lan wants=integrationtest/ci/run signed=host-privileged
  export who doing wants signed
  run -1 --separate-stderr format request.schema.json who who doing wants signed
  [ "$output" = "" ]
  [[ "$stderr" == *"who is named twice"* ]]
}

@test "a document the contract forbids is refused and not written" {
  version=1
  export version
  run -1 --separate-stderr format secret-get-response.schema.json version
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-response.schema.json"* ]]
}

@test "a field the contract does not govern is refused" {
  nosuch=1
  export nosuch
  run -1 --separate-stderr format secret-get-response.schema.json nosuch
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-response.schema.json"* ]]
}

@test "a value that is not the type the contract names is refused" {
  version=x value=y
  export version value
  run -1 --separate-stderr format secret-get-response.schema.json version value
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-response.schema.json"* ]]
}

@test "naming a contract that does not exist is refused, and says so differently" {
  who=tore
  export who
  run -1 --separate-stderr format no-such-contract.schema.json who
  [ "$output" = "" ]
  [[ "$stderr" == *"no contract named no-such-contract.schema.json"* ]]
}
