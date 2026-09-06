bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH= cd "$BATS_TEST_DIRNAME/../.." && pwd)
  PATH="$root/components/secret-manager:$root/components/contract:$PATH"
  SECRET_DIR=$(mktemp -d)
  export PATH SECRET_DIR
  command -v jsonschema > /dev/null || {
    echo "jsonschema is not installed; it is the validator this repository depends on" >&2
    return 1
  }
}

teardown() { rm -rf "$SECRET_DIR"; }

bundle() {
  jsonschema bundle -r "$root/contracts/defs.schema.json" "$root/contracts/$1"
}

validates() {
  bundle "$1" > "$BATS_TEST_TMPDIR/schema.json"
  printf '%s' "$2" > "$BATS_TEST_TMPDIR/doc.json"
  jsonschema validate "$BATS_TEST_TMPDIR/schema.json" "$BATS_TEST_TMPDIR/doc.json"
}

@test "what secret-get emits when it finds the secret matches its contract" {
  printf 'super-1' | secret-put '{"holder":"host-privileged","service":"integrationtest","version":1}'
  run --separate-stderr secret-get '{"holder":"host-privileged","service":"integrationtest"}'
  [ "$status" -eq 0 ]
  validates secret-get-response.schema.json "$output"
}

@test "what secret-get emits when the version is not there matches its contract" {
  printf 'super-1' | secret-put '{"holder":"host-privileged","service":"integrationtest","version":1}'
  run --separate-stderr secret-get '{"holder":"host-privileged","service":"integrationtest","version":2}'
  validates secret-get-response.schema.json "$output"
}

@test "a response claiming to be found without a value is refused" {
  run -2 validates secret-get-response.schema.json '{"found":true,"version":1}'
}

@test "a response claiming not to be found while carrying a value is refused" {
  run -2 validates secret-get-response.schema.json '{"found":false,"version":1,"value":"leaked"}'
}
