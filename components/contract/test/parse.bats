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
  fields=$(printf '%s' '{"holder":"johans-laptop","service":"github","version":1}' \
    | parse secret-put-request.schema.json holder service version)
  eval "$fields"
  [ "$holder" = "johans-laptop" ]
  [ "$service" = "github" ]
  [ "$version" = "1" ]
}

@test "a field the document does not carry yields an empty value" {
  fields=$(printf '%s' '{"holder":"johans-laptop","service":"github"}' \
    | parse secret-get-request.schema.json holder service version)
  eval "$fields"
  [ "$holder" = "johans-laptop" ]
  [ -z "$version" ]
}

@test "a field that is false yields false rather than nothing" {
  fields=$(printf '%s' '{"found":false,"version":2}' \
    | parse secret-get-response.schema.json found version)
  eval "$fields"
  [ "$found" = "false" ]
  [ "$version" = "2" ]
}

@test "a value cannot escape the assignment it is put in" {
  want="'; touch $BATS_TEST_TMPDIR/escaped; '"
  document=$(jq -nc --arg signed "$want" \
    '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}')
  fields=$(printf '%s' "$document" | parse request.schema.json signed)
  eval "$fields"
  [ "$signed" = "$want" ]
  [ ! -e "$BATS_TEST_TMPDIR/escaped" ]
}

@test "naming no field checks the document and yields nothing" {
  run -0 --separate-stderr reading secret-put-request.schema.json \
    '{"holder":"johans-laptop","service":"github","version":1}'
  [ "$output" = "" ]
  [ "$stderr" = "" ]
}

@test "a document missing a required field is refused" {
  run -1 --separate-stderr reading secret-put-request.schema.json \
    '{"holder":"johans-laptop"}' holder
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-put-request.schema.json"* ]]
}

@test "a field breaking its type is refused" {
  run -1 --separate-stderr reading secret-put-request.schema.json \
    '{"holder":"johans-laptop","service":"GitHub","version":1}' service
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-put-request.schema.json"* ]]
}

@test "a version below the first one the store can hold is refused" {
  run -1 --separate-stderr reading secret-put-request.schema.json \
    '{"holder":"johans-laptop","service":"github","version":-1}' version
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-put-request.schema.json"* ]]
}

@test "naming a contract that does not exist is refused, and says so differently" {
  run -1 --separate-stderr reading no-such-contract.schema.json '{}'
  [ "$output" = "" ]
  [[ "$stderr" == *"no contract named no-such-contract.schema.json"* ]]
}

@test "a document that is refused yields nothing to evaluate" {
  run -1 --separate-stderr reading secret-put-request.schema.json '{}' holder
  [ "$output" = "" ]
  [ -n "$stderr" ]
}

@test "a body that is not JSON at all is refused rather than read as empty" {
  run -1 --separate-stderr reading secret-put-request.schema.json 'not json' holder
  [ "$output" = "" ]
  [ -n "$stderr" ]
}

@test "an empty body is refused rather than read as an empty document" {
  run -1 --separate-stderr reading secret-put-request.schema.json '' holder
  [ "$output" = "" ]
  [ -n "$stderr" ]
}
