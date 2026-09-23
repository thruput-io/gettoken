bats_require_minimum_version 1.5.0

setup() {
  export BATS_LIB_PATH="/opt/homebrew/lib:/usr/local/lib:/usr/lib"
  bats_load_library bats-support 2>/dev/null || true
  bats_load_library bats-assert 2>/dev/null || true
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  PATH="$root/build/bin:$PATH:$root/src/components/entitlements"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR
}

refute_stderr_contains() {
  if command -v refute_regex >/dev/null 2>&1; then
    refute_regex "$stderr" "$1"
  else
    [[ "$stderr" != *"$1"* ]]
  fi
}

asking() {
  printf '%s' '{"who":"tore","doing":"mac.lan","signed":"host-privileged"}' | entitlements
}

@test "the capability the integrated tool is asked for is one the agent may equip" {
  run -0 --separate-stderr asking
  [ "$(printf '%s' "$output" | jq -r '.entitlements[] | select(.capability == "integrationtest/ci/run") | .capability')" = "integrationtest/ci/run" ]
  refute_stderr_contains "does not satisfy"
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
