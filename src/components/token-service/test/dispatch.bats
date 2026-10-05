bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

setup() {
  root=$ROOT_DIR
  STUB_DIR=$(mktemp -d)
  PATH="$STUB_DIR:$root/src/components/token-service:$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  HANDED_FILE="$STUB_DIR/handed-to-the-exchanger"
  export PATH CONTRACTS_DIR HANDED_FILE
}

teardown() { rm -rf "$STUB_DIR"; }

exchanger_that() {
  printf '%s\n' '#!/bin/sh' 'cat > "$HANDED_FILE"' "$1" > "$STUB_DIR/exchanger"
  chmod 755 "$STUB_DIR/exchanger"
}

wanting() {
  jq -nc --arg wants "$1" \
    '{who:"tore",doing:"mac.lan",wants:$wants,signed:"host-privileged"}'
}

dispatch() { printf '%s' "$1" | token-service; }

asking() { dispatch "$(wanting "$1")"; }

@test "the exchanger is handed who is asking and what for, and what it answers is handed back" {
  exchanger_that 'echo "{\"access_token\":\"narrow-token\",\"expires_in\":120}"'
  run -0 --separate-stderr asking integrationtest/ci/run
  [ "$(jq -c -S . < "$HANDED_FILE")" = '{"wants":"integrationtest/ci/run","who":"tore"}' ]
  [ "$(printf '%s' "$output" | jq -c -S .)" = '{"access_token":"narrow-token","expires_in":120}' ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "an exchanger claiming a lifetime shorter than a minute hands over nothing" {
  exchanger_that 'echo "{\"access_token\":\"narrow-token\",\"expires_in\":1}"'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-response.schema.json\nvalidating https://thruput.io/gettoken/response.schema.json: validating /properties/expires_in: validating /$defs/ExpiresIn: minimum: 1/1 is less than 60.000000')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an exchanger claiming a lifetime longer than a day hands over nothing" {
  exchanger_that 'echo "{\"access_token\":\"narrow-token\",\"expires_in\":86401}"'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-response.schema.json\nvalidating https://thruput.io/gettoken/response.schema.json: validating /properties/expires_in: validating /$defs/ExpiresIn: maximum: 86401/1 is greater than 86400.000000')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a request naming no capability is refused by the contract, and the exchanger is never asked" {
  exchanger_that 'echo "{\"access_token\":\"narrow-token\",\"expires_in\":120}"'
  run -1 --separate-stderr dispatch '{"who":"tore","doing":"mac.lan","signed":"host-privileged"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: required: missing properties: ["wants"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
  [ ! -f "$HANDED_FILE" ]
}

@test "a capability whose first segment climbs out of a directory never reaches the exchanger" {
  exchanger_that 'echo "{\"access_token\":\"narrow-token\",\"expires_in\":120}"'
  run -1 --separate-stderr asking ../../bin/sh
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/wants: validating /$defs/Capability: pattern: "../../bin/sh" does not match regular expression "^[a-z0-9-]+(/[a-z0-9._-]+)+$"')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
  [ ! -f "$HANDED_FILE" ]
}

@test "a capability whose first segment names the current directory never reaches the exchanger" {
  exchanger_that 'echo "{\"access_token\":\"narrow-token\",\"expires_in\":120}"'
  run -1 --separate-stderr asking ./ci/run
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/wants: validating /$defs/Capability: pattern: "./ci/run" does not match regular expression "^[a-z0-9-]+(/[a-z0-9._-]+)+$"')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
  [ ! -f "$HANDED_FILE" ]
}

@test "a capability ending in a newline never reaches the exchanger" {
  exchanger_that 'echo "{\"access_token\":\"narrow-token\",\"expires_in\":120}"'
  run -1 --separate-stderr dispatch \
    "$(jq -nc '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run\n",signed:"host-privileged"}')"
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/wants: validating /$defs/Capability: pattern: "integrationtest/ci/run\\n" does not match regular expression "^[a-z0-9-]+(/[a-z0-9._-]+)+$"')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
  [ ! -f "$HANDED_FILE" ]
}

@test "an exchanger answering with no lifetime is refused" {
  exchanger_that 'echo "{\"access_token\":\"narrow-token\"}"'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-response.schema.json\nvalidating https://thruput.io/gettoken/response.schema.json: required: missing properties: ["expires_in"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an exchanger answering with something that is not a document is refused" {
  exchanger_that 'printf "%s\n" narrow-token'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "parse: the document is not JSON: invalid character 'a' in literal null (expecting 'u')"
}

@test "an exchanger that fails takes the request down with it, and says so" {
  exchanger_that 'exit 1'
  run -1 --separate-stderr asking integrationtest/ci/run
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "token-service: the exchanger serving integrationtest/ci/run failed"
}
