bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH= cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/components/contract:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

@test "what format writes, parse reads back" {
  document=$(format request.schema.json who=tore doing=mac.lan wants=integrationtest/ci/run signed=host-privileged)
  fields=$(printf '%s' "$document" | parse request.schema.json who doing wants signed)
  eval "$fields"
  [ "$who" = "tore" ]
  [ "$doing" = "mac.lan" ]
  [ "$wants" = "integrationtest/ci/run" ]
  [ "$signed" = "host-privileged" ]
}

@test "a field the contract types as a number is written as a number" {
  document=$(format response.schema.json access_token=narrow expires_in=120)
  [ "$(printf '%s' "$document" | jq -r '.expires_in | type')" = "number" ]
  [ "$(printf '%s' "$document" | jq -r '.access_token | type')" = "string" ]
}

@test "a field the contract types as a boolean is written as a boolean" {
  document=$(format secret-get-response.schema.json found=false version=2)
  [ "$(printf '%s' "$document" | jq -r '.found | type')" = "boolean" ]
  [ "$(printf '%s' "$document" | jq -r '.found')" = "false" ]
}

@test "a value the command line must not carry is read from a file" {
  printf 'super-1' > "$BATS_TEST_TMPDIR/secret"
  document=$(format secret-get-response.schema.json found=true version=1 "value=@$BATS_TEST_TMPDIR/secret")
  [ "$(printf '%s' "$document" | jq -r '.value')" = "super-1" ]
}

@test "a value is read from standard input when the file is named -" {
  document=$(printf 'super-1' | format secret-get-response.schema.json found=true version=1 value=@-)
  [ "$(printf '%s' "$document" | jq -r '.value')" = "super-1" ]
}

@test "a document the contract forbids is refused and not written" {
  run -1 --separate-stderr format secret-get-response.schema.json found=false version=1 value=leaked
  [ "$output" = "" ]
  [ -n "$stderr" ]
}

@test "a field the contract does not govern is refused" {
  run -1 --separate-stderr format secret-get-response.schema.json nosuch=1
}

@test "a value that is not the type the contract names is refused" {
  run -1 --separate-stderr format secret-get-response.schema.json found=true version=x value=y
}

@test "an argument that names no field is refused" {
  run -1 --separate-stderr format request.schema.json who
}

@test "naming a contract that does not exist is refused" {
  run -1 --separate-stderr format no-such-contract.schema.json who=tore
}
