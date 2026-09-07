bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

@test "a value that is not JSON is the one that gets quoted" {
  document=$(format request.schema.json who=tore doing=mac.lan wants=integrationtest/ci/run signed=host-privileged)
  [ "$(printf '%s' "$document" | jq -r '.who | type')" = "string" ]
  [ "$(printf '%s' "$document" | jq -r '.wants | type')" = "string" ]
}

@test "a value that is a number goes in as a number" {
  document=$(format response.schema.json access_token=narrow expires_in=120)
  [ "$(printf '%s' "$document" | jq -r '.expires_in | type')" = "number" ]
  [ "$(printf '%s' "$document" | jq -r '.access_token | type')" = "string" ]
}

@test "a value that is a boolean goes in as a boolean" {
  document=$(format secret-get-response.schema.json found=false version=2)
  [ "$(printf '%s' "$document" | jq -r '.found | type')" = "boolean" ]
  [ "$(printf '%s' "$document" | jq -r '.found')" = "false" ]
}

@test "a value the command line must not carry is read from a file" {
  printf 'super-1' > "$BATS_TEST_TMPDIR/secret"
  document=$(format secret-get-response.schema.json found=true version=1 "value@$BATS_TEST_TMPDIR/secret")
  [ "$(printf '%s' "$document" | jq -r '.value')" = "super-1" ]
}

@test "a value is read from standard input when the file is named -" {
  document=$(printf 'super-1' | format secret-get-response.schema.json found=true version=1 value@-)
  [ "$(printf '%s' "$document" | jq -r '.value')" = "super-1" ]
}

@test "a value read from a file stays a string even when it reads as JSON" {
  printf '12345' > "$BATS_TEST_TMPDIR/secret"
  document=$(format secret-get-response.schema.json found=true version=1 "value@$BATS_TEST_TMPDIR/secret")
  [ "$(printf '%s' "$document" | jq -r '.value | type')" = "string" ]
  [ "$(printf '%s' "$document" | jq -r '.value')" = "12345" ]
}

@test "an @ inside a value is a value, not a file to read" {
  run -1 --separate-stderr format request.schema.json \
    who=tore doing=mac.lan "wants=@$BATS_TEST_TMPDIR/nosuch" signed=host-privileged
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy request.schema.json"* ]]
}

@test "a file that is not there is refused, and says which" {
  run -1 --separate-stderr format secret-get-response.schema.json \
    found=true version=1 "value@$BATS_TEST_TMPDIR/nosuch"
  [ "$output" = "" ]
  [[ "$stderr" == *"nosuch"* ]]
}

@test "a field filled twice is refused rather than taking the last one" {
  run -1 --separate-stderr format request.schema.json \
    who=tore who=eve doing=mac.lan wants=integrationtest/ci/run signed=host-privileged
  [ "$output" = "" ]
  [[ "$stderr" == *"who is filled twice"* ]]
}

@test "a document the contract forbids is refused and not written" {
  run -1 --separate-stderr format secret-get-response.schema.json found=false version=1 value=leaked
  [ "$output" = "" ]
  [ -n "$stderr" ]
}

@test "a field the contract does not govern is refused" {
  run -1 --separate-stderr format secret-get-response.schema.json nosuch=1
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-response.schema.json"* ]]
}

@test "a value that is not the type the contract names is refused" {
  run -1 --separate-stderr format secret-get-response.schema.json found=true version=x value=y
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-response.schema.json"* ]]
}

@test "an argument that fills no field is refused, and says what one looks like" {
  run -1 --separate-stderr format request.schema.json who
  [ "$output" = "" ]
  [[ "$stderr" == *"fills no field"* ]]
}

@test "naming a contract that does not exist is refused, and says so differently" {
  run -1 --separate-stderr format no-such-contract.schema.json who=tore
  [ "$output" = "" ]
  [[ "$stderr" == *"no contract named no-such-contract.schema.json"* ]]
}
