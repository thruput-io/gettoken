bats_require_minimum_version 1.5.0

load '../../../../scripts/test/helper'

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR
}

admits() { printf '%s' "$2" | parse "$1"; }

requesting() {
  jq -nc --arg signed "$1" \
    '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}'
}

@test "a request whose signature is ordinary text is admitted" {
  run -0 --separate-stderr admits token-request.schema.json "$(requesting host-privileged)"
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a request whose signature carries a control character is refused" {
  run -1 --separate-stderr admits token-request.schema.json "$(requesting "host$(printf '\001')privileged")"
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/signed: validating /$defs/Signature: not: validated against <anonymous schema>')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a request whose signature carries a delete character is refused" {
  run -1 --separate-stderr admits token-request.schema.json "$(requesting "host$(printf '\177')privileged")"
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/signed: validating /$defs/Signature: not: validated against <anonymous schema>')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a request whose signature ends in a newline is refused" {
  run -1 --separate-stderr admits token-request.schema.json \
    "$(jq -nc '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:"host-privileged\n"}')"
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/signed: validating /$defs/Signature: not: validated against <anonymous schema>')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a capability ending in a newline is refused" {
  run -1 --separate-stderr admits token-request.schema.json \
    "$(jq -nc '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run\n",signed:"host-privileged"}')"
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/wants: validating /$defs/Capability: pattern: "integrationtest/ci/run\\n" does not match regular expression "^[a-z0-9-]+(/[a-z0-9._-]+)+$"')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an agent name ending in a newline is refused" {
  run -1 --separate-stderr admits token-request.schema.json \
    "$(jq -nc '{who:"tore\n",doing:"mac.lan",wants:"integrationtest/ci/run",signed:"host-privileged"}')"
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-request.schema.json\nvalidating https://thruput.io/gettoken/request.schema.json: validating /properties/who: validating /$defs/Agent: pattern: "tore\\n" does not match regular expression "^[A-Za-z0-9._-]+$"')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a minute and a day are both admitted as lifetimes" {
  run -0 --separate-stderr admits token-response.schema.json '{"access_token":"narrow","expires_in":60}'
  assert_equal "$(without_kcov_trace "$stderr")" ""
  run -0 --separate-stderr admits token-response.schema.json '{"access_token":"narrow","expires_in":86400}'
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a lifetime shorter than a minute is refused" {
  run -1 --separate-stderr admits token-response.schema.json '{"access_token":"narrow","expires_in":59}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-response.schema.json\nvalidating https://thruput.io/gettoken/response.schema.json: validating /properties/expires_in: validating /$defs/ExpiresIn: minimum: 59/1 is less than 60.000000')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a lifetime longer than a day is refused" {
  run -1 --separate-stderr admits token-response.schema.json '{"access_token":"narrow","expires_in":86401}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-response.schema.json\nvalidating https://thruput.io/gettoken/response.schema.json: validating /properties/expires_in: validating /$defs/ExpiresIn: maximum: 86401/1 is greater than 86400.000000')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a response carrying a field the contract does not govern is refused" {
  run -1 --separate-stderr admits token-response.schema.json \
    '{"access_token":"narrow","expires_in":120,"wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy token-response.schema.json\nvalidating https://thruput.io/gettoken/response.schema.json: unexpected additional properties ["wants"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an exchange request naming who is asking and what for is admitted" {
  run -0 --separate-stderr admits exchange-request.schema.json \
    '{"who":"tore","wants":"integrationtest/ci/run"}'
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "an exchange request naming no agent is refused" {
  run -1 --separate-stderr admits exchange-request.schema.json '{"wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy exchange-request.schema.json\nvalidating https://thruput.io/gettoken/exchange-request.schema.json: required: missing properties: ["who"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an exchange request does not carry the signature the request was signed with" {
  run -1 --separate-stderr admits exchange-request.schema.json \
    '{"who":"tore","wants":"integrationtest/ci/run","signed":"host-privileged"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy exchange-request.schema.json\nvalidating https://thruput.io/gettoken/exchange-request.schema.json: unexpected additional properties ["signed"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an exchange request does not carry what the agent was doing" {
  run -1 --separate-stderr admits exchange-request.schema.json \
    '{"who":"tore","wants":"integrationtest/ci/run","doing":"mac.lan"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy exchange-request.schema.json\nvalidating https://thruput.io/gettoken/exchange-request.schema.json: unexpected additional properties ["doing"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}
