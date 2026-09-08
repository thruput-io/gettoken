bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

@test "what format writes, parse reads back" {
  who=tore doing=mac.lan wants=integrationtest/ci/run signed=host-privileged
  export who doing wants signed
  document=$(format token-request.schema.json who doing wants signed)

  unset who doing wants signed
  eval "$(printf '%s' "$document" | parse token-request.schema.json who doing wants signed)"
  [ "$who" = "tore" ]
  [ "$doing" = "mac.lan" ]
  [ "$wants" = "integrationtest/ci/run" ]
  [ "$signed" = "host-privileged" ]
}

@test "what format writes for a number, parse reads back as that number" {
  access_token=narrow expires_in=120
  export access_token expires_in
  document=$(format token-response.schema.json access_token expires_in)

  unset access_token expires_in
  eval "$(printf '%s' "$document" | parse token-response.schema.json access_token expires_in)"
  [ "$access_token" = "narrow" ]
  [ "$expires_in" = "120" ]
}
