bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

setup() {
  root=$ROOT_DIR
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR
}

reading() {
  contract=$1
  document=$2
  shift 2
  printf '%s' "$document" | parse "$contract" "$@"
}

probing() {
  CONTRACTS_DIR=$BATS_TEST_TMPDIR/contracts
  cp -R "$root/src/contracts" "$CONTRACTS_DIR"
  cat > "$CONTRACTS_DIR/probe.schema.json" <<'SCHEMA'
{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://thruput.io/gettoken/probe.schema.json","type":"object","additionalProperties":false,"properties":{"flag":{"type":"boolean"},"nothing":{"type":"null"}}}
SCHEMA
}

@test "a document satisfying its contract yields the fields it was asked for" {
  run -0 --separate-stderr reading secret-put-request.schema.json \
    '{"key":"johans-laptop/github","value":"super-1"}' key value
  [ "$output" = "$(printf "key='johans-laptop/github'\nvalue='super-1'")" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a field the document does not carry yields an empty value" {
  run -0 --separate-stderr reading secret-put-request.schema.json \
    '{"key":"johans-laptop/github","value":"super-1"}' key version
  [ "$output" = "$(printf "key='johans-laptop/github'\nversion=''")" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a field that is false yields false rather than nothing" {
  probing
  run -0 --separate-stderr reading probe.schema.json '{"flag":false}' flag
  [ "$output" = "flag='false'" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a field that is null yields an empty value" {
  probing
  run -0 --separate-stderr reading probe.schema.json '{"nothing":null}' nothing
  [ "$output" = "nothing=''" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a value cannot escape the assignment it is put in" {
  want="'; touch $BATS_TEST_TMPDIR/escaped; '"
  document=$(jq -nc --arg signed "$want" \
    '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}')
  run -0 --separate-stderr reading token-request.schema.json "$document" signed
  signed=''
  eval "$output"
  [ "$signed" = "$want" ]
  [ ! -e "$BATS_TEST_TMPDIR/escaped" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "naming no field checks the document and yields nothing" {
  run -0 --separate-stderr reading secret-put-request.schema.json \
    '{"key":"johans-laptop/github","value":"super-1"}'
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a document missing a required field is refused" {
  run -1 --separate-stderr reading secret-put-request.schema.json \
    '{}' key
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy secret-put-request.schema.json\nvalidating https://thruput.io/gettoken/secret-request.schema.json: required: missing properties: ["key" "value"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a field breaking its type is refused" {
  run -1 --separate-stderr reading secret-put-request.schema.json \
    '{"key":"Johans-Laptop","value":"super-1"}' key
  [ "$output" = "" ]
  expected=$(printf "parse: the document does not satisfy secret-put-request.schema.json\nvalidating https://thruput.io/gettoken/secret-request.schema.json: validating /properties/key: validating /\$defs/Key: pattern: \"Johans-Laptop\" does not match regular expression \"^[a-z0-9-]+(/[a-z0-9-]+)*\$\"")
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a version below the first one the store can hold is refused" {
  run -1 --separate-stderr reading secret-get-request-version.schema.json \
    '{"key":"johans-laptop/github","version":-1}' version
  [ "$output" = "" ]
  expected=$(printf "parse: the document does not satisfy secret-get-request-version.schema.json\nvalidating https://thruput.io/gettoken/secret-request-key.schema.json: validating /properties/version: validating /\$defs/Version: minimum: -1/1 is less than 0.000000")
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "naming a contract that does not exist is refused, and says so differently" {
  run -1 --separate-stderr reading no-such-contract.schema.json '{}'
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "parse: no contract named no-such-contract.schema.json in $root/src/contracts"
}

@test "a body that is not JSON at all is refused rather than read as empty" {
  run -1 --separate-stderr reading secret-put-request.schema.json 'not json' key
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "parse: the document is not JSON: invalid character 'o' in literal null (expecting 'u')"
}

@test "an empty body is refused rather than read as an empty document" {
  run -1 --separate-stderr reading secret-put-request.schema.json '' key
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "parse: the document is not JSON: unexpected end of JSON input"
}
