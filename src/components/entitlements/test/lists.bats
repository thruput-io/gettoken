bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

setup() {
  root=$ROOT_DIR
  PATH="$root/build/bin:$root/src/components/entitlements:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR
}

asking() {
  printf '%s' '{"who":"tore","doing":"mac.lan","signed":"host-privileged"}' | entitlements
}

@test "the capability the integrated tool is asked for is one the agent may equip" {
  run -0 --separate-stderr asking
  [ "$output" = '{"entitlements":[{"capability":"integrationtest/ci/run","description":"Run the integration test suite on CI.","variables":[]}]}' ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "every capability listed says what it is for" {
  run -0 --separate-stderr asking
  [ "$(printf '%s' "$output" | jq -r '.entitlements[] | select(.description == "") | .capability')" = "" ]
  [ "$(printf '%s' "$output" | jq '[.entitlements[] | select(has("description") | not)] | length')" = 0 ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a request naming a capability is refused, because none is being asked for" {
  run -1 --separate-stderr sh -c 'printf "%s" "{\"who\":\"tore\",\"doing\":\"mac.lan\",\"signed\":\"host-privileged\",\"wants\":\"integrationtest/ci/run\"}" | entitlements'
  [ "$output" = "" ]
  expected=$(printf "parse: the document does not satisfy entitlements-request.schema.json\nvalidating https://thruput.io/gettoken/entitlements-request.schema.json: unexpected additional properties [\"wants\"]")
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}
