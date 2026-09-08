bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

admits() { printf '%s' "$2" | parse "$1"; }

@test "entitlements naming what they are and what their variables mean are admitted" {
  run -0 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"github/{org}/{repo}/pr/create","description":"Open a pull request.","variables":[{"name":"org","description":"The organisation that owns the repository."},{"name":"repo","description":"The repository to open the pull request against."}]}]}'
  [ "$stderr" = "" ]
}

@test "an entitlement that does not say what it is for is refused" {
  run -1 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"integrationtest/ci/run","variables":[]}]}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy entitlements-response.schema.json"* ]]
}

@test "an entitlement that leaves its variables unlisted is refused" {
  run -1 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"github/{org}/{repo}/pr/create","description":"Open a pull request."}]}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy entitlements-response.schema.json"* ]]
}

@test "a variable that is not named and explained is refused" {
  run -1 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"github/{org}/{repo}/pr/create","description":"Open a pull request.","variables":[{"name":"org"}]}]}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy entitlements-response.schema.json"* ]]
}

@test "an entitlements request carries no capability, because none is being asked for" {
  run -1 --separate-stderr admits entitlements-request.schema.json \
    '{"who":"tore","doing":"mac.lan","signed":"host-privileged","wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy entitlements-request.schema.json"* ]]
}
