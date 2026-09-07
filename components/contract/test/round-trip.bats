bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
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

@test "what format writes for a number, parse reads back as that number" {
  document=$(format response.schema.json access_token=narrow expires_in=120)
  fields=$(printf '%s' "$document" | parse response.schema.json access_token expires_in)
  eval "$fields"
  [ "$access_token" = "narrow" ]
  [ "$expires_in" = "120" ]
}
