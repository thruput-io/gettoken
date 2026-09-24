bats_require_minimum_version 1.5.0

load '../../../../scripts/test/helper'

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  PATH="$root/src/components/token-service:$root/build/bin:$PATH"
  EXCHANGER_DIR=$(mktemp -d)
  CONTRACTS_DIR="$root/src/contracts"
  export PATH EXCHANGER_DIR CONTRACTS_DIR
}

teardown() { rm -rf "$EXCHANGER_DIR"; }

register() {
  printf '%s\n' '#!/bin/sh' "$2" > "$EXCHANGER_DIR/$1"
  chmod 755 "$EXCHANGER_DIR/$1"
}

wanting() {
  jq -nc --arg wants "$1" \
    '{who:"tore",doing:"mac.lan",wants:$wants,signed:"host-privileged"}'
}

dispatch() { printf '%s' "$1" | token-service; }

asking() { dispatch "$(wanting "$1")"; }

@test "the exchanger registered for the first segment is handed the whole capability" {
  register integrationtest 'eval "$(parse exchange-request.schema.json wants)"; access_token=$wants; expires_in=120; export access_token expires_in; format token-response.schema.json access_token expires_in'
  run -0 --separate-stderr asking integrationtest/ci/run
  [ "$(printf '%s' "$output" | jq -r '.access_token')" = "integrationtest/ci/run" ]
  [ "$(printf '%s' "$output" | jq -r '.expires_in')" = "120" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "an exchanger claiming a lifetime shorter than a minute hands over nothing" {
  register integrationtest 'echo "{\"access_token\":\"narrow-token\",\"expires_in\":1}"'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-response.schema.json\nvalidating https://thruput.io/gettoken/response.schema.json: validating /properties/expires_in: validating /$defs/ExpiresIn: minimum: 1/1 is less than 60.000000')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an exchanger claiming a lifetime longer than a day hands over nothing" {
  register integrationtest 'echo "{\"access_token\":\"narrow-token\",\"expires_in\":86401}"'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-response.schema.json\nvalidating https://thruput.io/gettoken/response.schema.json: validating /properties/expires_in: validating /$defs/ExpiresIn: maximum: 86401/1 is greater than 86400.000000')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a request naming no capability is refused by the contract" {
  run -1 --separate-stderr dispatch '{"who":"tore","doing":"mac.lan","signed":"host-privileged"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: required: missing properties: ["wants"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a capability no exchanger serves is refused by the lookup" {
  run -1 --separate-stderr asking nosuch/capability
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "token-service: no exchanger serves nosuch/capability"
}

@test "a capability whose first segment climbs out of the exchanger directory never reaches the lookup" {
  run -1 --separate-stderr asking ../../bin/sh
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/wants: validating /$defs/Capability: pattern: "../../bin/sh" does not match regular expression "^[a-z0-9-]+(/[a-z0-9._-]+)+$"')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a capability whose first segment names the exchanger directory itself never reaches the lookup" {
  run -1 --separate-stderr asking ./ci/run
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/wants: validating /$defs/Capability: pattern: "./ci/run" does not match regular expression "^[a-z0-9-]+(/[a-z0-9._-]+)+$"')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a capability ending in a newline never reaches the lookup" {
  run -1 --separate-stderr dispatch \
    "$(jq -nc '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run\n",signed:"host-privileged"}')"
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/wants: validating /$defs/Capability: pattern: "integrationtest/ci/run\\n" does not match regular expression "^[a-z0-9-]+(/[a-z0-9._-]+)+$"')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an exchanger answering with no lifetime is refused" {
  register integrationtest 'echo "{\"access_token\":\"narrow-token\"}"'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-response.schema.json\nvalidating https://thruput.io/gettoken/response.schema.json: required: missing properties: ["expires_in"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an exchanger answering with something that is not a document is refused" {
  register integrationtest 'printf "%s\n" narrow-token'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "parse: the document is not JSON: invalid character 'a' in literal null (expecting 'u')"
}

@test "an exchanger that fails takes the request down with it, and says so" {
  register integrationtest 'exit 1'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "token-service: the exchanger serving integrationtest/ci/run failed"
}
