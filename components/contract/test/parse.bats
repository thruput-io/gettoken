bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

reading() {
  contract=$1
  document=$2
  shift 2
  printf '%s' "$document" | parse "$contract" "$@"
}

@test "a document satisfying its contract yields the fields it was asked for" {
  fields=$(printf '%s' '{"key":"johans-laptop/github","value":"super-1"}' \
    | parse secret-put-request.schema.json key value)
  eval "$fields"
  [ "$key" = "johans-laptop/github" ]
  [ "$value" = "super-1" ]
}

@test "a field the document does not carry yields an empty value" {
  fields=$(printf '%s' '{"key":"johans-laptop/github","version":0}' \
    | parse secret-get-request-version.schema.json key version)
  eval "$fields"
  [ "$key" = "johans-laptop/github" ]
  [ "$version" = "0" ]
}

@test "a field that is false yields false rather than nothing" {
  fields=$(printf '%s' '{"version":2,"value":"super-1"}' \
    | parse secret-get-response.schema.json version value)
  eval "$fields"
  [ "$version" = "2" ]
  [ "$value" = "super-1" ]
}

@test "a value cannot escape the assignment it is put in" {
  want="'; touch $BATS_TEST_TMPDIR/escaped; '"
  document=$(jq -nc --arg signed "$want" \
    '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}')
  fields=$(printf '%s' "$document" | parse token-request.schema.json signed)
  eval "$fields"
  [ "$signed" = "$want" ]
  [ ! -e "$BATS_TEST_TMPDIR/escaped" ]
}

@test "naming no field checks the document and yields nothing" {
  run -0 --separate-stderr reading secret-put-request.schema.json \
    '{"key":"johans-laptop/github","value":"super-1"}'
  [ "$output" = "" ]
  [ "$stderr" = "" ]
}

@test "a document missing a required field is refused" {
  run -1 --separate-stderr reading secret-put-request.schema.json \
    '{}' key
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-put-request.schema.json"* ]]
}

@test "a field breaking its type is refused" {
  run -1 --separate-stderr reading secret-put-request.schema.json \
    '{"key":"Johans-Laptop","value":"super-1"}' key
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-put-request.schema.json"* ]]
}

@test "a version below the first one the store can hold is refused" {
  run -1 --separate-stderr reading secret-get-request-version.schema.json \
    '{"key":"johans-laptop/github","version":-1}' version
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-request-version.schema.json"* ]]
}

@test "naming a contract that does not exist is refused, and says so differently" {
  run -1 --separate-stderr reading no-such-contract.schema.json '{}'
  [ "$output" = "" ]
  [[ "$stderr" == *"no contract named no-such-contract.schema.json"* ]]
}

@test "a document that is refused yields nothing to evaluate" {
  run -1 --separate-stderr reading secret-put-request.schema.json '{}' key
  [ "$output" = "" ]
  [ -n "$stderr" ]
}

@test "a body that is not JSON at all is refused rather than read as empty" {
  run -1 --separate-stderr reading secret-put-request.schema.json 'not json' key
  [ "$output" = "" ]
  [ -n "$stderr" ]
}

@test "an empty body is refused rather than read as an empty document" {
  run -1 --separate-stderr reading secret-put-request.schema.json '' key
  [ "$output" = "" ]
  [ -n "$stderr" ]
}
