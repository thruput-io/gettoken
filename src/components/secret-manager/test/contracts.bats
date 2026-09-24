bats_require_minimum_version 1.5.0

load '../../../../scripts/test/helper'

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR
}

admits() { printf '%s' "$2" | parse "$1"; }

@test "a secret response carrying no secret is refused, because there is no such answer" {
  run -1 --separate-stderr admits secret-get-response.schema.json '{"version":1}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy secret-get-response.schema.json\nvalidating https://thruput.io/gettoken/secret-response.schema.json: required: missing properties: ["value"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a secret response saying whether it found anything is refused, because the status says" {
  run -1 --separate-stderr admits secret-get-response.schema.json \
    '{"found":true,"version":1,"value":"super-1"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy secret-get-response.schema.json\nvalidating https://thruput.io/gettoken/secret-response.schema.json: unexpected additional properties ["found"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "the first version and the last one the store can hold are both admitted" {
  run -0 --separate-stderr admits secret-get-request-version.schema.json '{"key":"johans-laptop/github","version":0}'
  assert_equal "$(without_kcov_trace "$stderr")" ""
  run -0 --separate-stderr admits secret-get-request-version.schema.json '{"key":"johans-laptop/github","version":1000000}'
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a version before the first one the store can hold is refused" {
  run -1 --separate-stderr admits secret-get-request-version.schema.json '{"key":"johans-laptop/github","version":-1}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy secret-get-request-version.schema.json\nvalidating https://thruput.io/gettoken/secret-request-key.schema.json: validating /properties/version: validating /$defs/Version: minimum: -1/1 is less than 0.000000')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a version past the last one the store can hold is refused" {
  run -1 --separate-stderr admits secret-get-request-version.schema.json '{"key":"johans-laptop/github","version":1000001}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy secret-get-request-version.schema.json\nvalidating https://thruput.io/gettoken/secret-request-key.schema.json: validating /properties/version: validating /$defs/Version: maximum: 1000001/1 is greater than 1000000.000000')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a secret response says which version and value it carried" {
  run -0 --separate-stderr admits secret-get-response.schema.json \
    '{"version":0,"value":"super-1"}'
  assert_equal "$(without_kcov_trace "$stderr")" ""
}
