bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

admits() { printf '%s' "$2" | parse "$1"; }

@test "a secret response carrying no secret is refused, because there is no such answer" {
  run -1 --separate-stderr admits secret-get-response.schema.json '{"version":1}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-response.schema.json"* ]]
}

@test "a secret response saying whether it found anything is refused, because the status says" {
  run -1 --separate-stderr admits secret-get-response.schema.json \
    '{"found":true,"version":1,"value":"super-1"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-response.schema.json"* ]]
}

@test "the first version and the last one the store can hold are both admitted" {
  run -0 --separate-stderr admits secret-get-request-version.schema.json '{"key":"johans-laptop/github","version":0}'
  [ "$stderr" = "" ]
  run -0 --separate-stderr admits secret-get-request-version.schema.json '{"key":"johans-laptop/github","version":1000000}'
  [ "$stderr" = "" ]
}

@test "a version before the first one the store can hold is refused" {
  run -1 --separate-stderr admits secret-get-request-version.schema.json '{"key":"johans-laptop/github","version":-1}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-request-version.schema.json"* ]]
}

@test "a version past the last one the store can hold is refused" {
  run -1 --separate-stderr admits secret-get-request-version.schema.json '{"key":"johans-laptop/github","version":1000001}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-request-version.schema.json"* ]]
}

@test "a secret response says which version and value it carried" {
  run -0 --separate-stderr admits secret-get-response.schema.json \
    '{"version":0,"value":"super-1"}'
  [ "$stderr" = "" ]
}
