bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$root/components/entitlements:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

asking() {
  printf '%s' '{"who":"tore","doing":"mac.lan","signed":"host-privileged"}' | entitlements
}

@test "the capability the integrated tool is asked for is one the agent may equip" {
  run -0 --separate-stderr asking
  [ "$(printf '%s' "$output" | jq -r '.entitlements[] | select(.capability == "integrationtest/ci/run") | .capability')" = "integrationtest/ci/run" ]
  [ "$stderr" = "" ]
}

@test "every capability listed says what it is for" {
  run -0 --separate-stderr asking
  [ "$(printf '%s' "$output" | jq -r '.entitlements[] | select(.description == "") | .capability')" = "" ]
  [ "$(printf '%s' "$output" | jq '[.entitlements[] | select(has("description") | not)] | length')" = 0 ]
}

@test "a request naming a capability is refused, because none is being asked for" {
  run -1 --separate-stderr sh -c 'printf "%s" "{\"who\":\"tore\",\"doing\":\"mac.lan\",\"signed\":\"host-privileged\",\"wants\":\"integrationtest/ci/run\"}" | entitlements'
  [ "$output" = "" ]
}
