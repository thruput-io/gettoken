bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

setup() {
  root=$ROOT_DIR
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  export PATH CONTRACTS_DIR
}

admits() { printf '%s' "$2" | parse "$1"; }

@test "entitlements naming what they are and what their variables mean are admitted" {
  run -0 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"github/{org}/{repo}/pr/create","description":"Open a pull request.","variables":[{"name":"org","description":"The organisation that owns the repository."},{"name":"repo","description":"The repository to open the pull request against."}]}]}'
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "an entitlement that does not say what it is for is refused" {
  run -1 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"integrationtest/ci/run","variables":[]}]}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy entitlements-response.schema.json\nvalidating https://thruput.io/gettoken/entitlements-response.schema.json: validating /properties/entitlements: validating /properties/entitlements/items: required: missing properties: ["description"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an entitlement that leaves its variables unlisted is refused" {
  run -1 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"github/{org}/{repo}/pr/create","description":"Open a pull request."}]}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy entitlements-response.schema.json\nvalidating https://thruput.io/gettoken/entitlements-response.schema.json: validating /properties/entitlements: validating /properties/entitlements/items: required: missing properties: ["variables"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "a variable that is not named and explained is refused" {
  run -1 --separate-stderr admits entitlements-response.schema.json \
    '{"entitlements":[{"capability":"github/{org}/{repo}/pr/create","description":"Open a pull request.","variables":[{"name":"org"}]}]}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy entitlements-response.schema.json\nvalidating https://thruput.io/gettoken/entitlements-response.schema.json: validating /properties/entitlements: validating /properties/entitlements/items: validating /properties/entitlements/items/properties/variables: validating /properties/entitlements/items/properties/variables/items: required: missing properties: ["description"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}

@test "an entitlements request carries no capability, because none is being asked for" {
  run -1 --separate-stderr admits entitlements-request.schema.json \
    '{"who":"tore","doing":"mac.lan","signed":"host-privileged","wants":"integrationtest/ci/run"}'
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy entitlements-request.schema.json\nvalidating https://thruput.io/gettoken/entitlements-request.schema.json: unexpected additional properties ["wants"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}
