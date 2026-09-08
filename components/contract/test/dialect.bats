bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

admits() { printf '%s' "$2" | parse "$1"; }

@test "the validator implements the dialect the contracts declare" {
  probe=$(mktemp -d)
  cp "$root/contracts"/*.schema.json "$probe"
  jq -n '{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://thruput.io/gettoken/dialect.schema.json",
    type: "object",
    dependentRequired: { paid: ["method"] }
  }' > "$probe/dialect.schema.json"
  CONTRACTS_DIR="$probe"
  run -1 --separate-stderr admits dialect.schema.json '{"paid":true}'
  rm -rf "$probe"
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy dialect.schema.json"* ]]
}
