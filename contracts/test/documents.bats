bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH= cd "$BATS_TEST_DIRNAME/../.." && pwd)
  PATH="$root/components/secret-manager:$root/components/contract:$PATH"
  SECRET_DIR=$(mktemp -d)
  CONTRACTS_DIR="$root/contracts"
  export PATH SECRET_DIR CONTRACTS_DIR
  command -v json-schema-eval > /dev/null || {
    echo "json-schema-eval is not installed; it is the validator this repository depends on" >&2
    return 1
  }
}

teardown() { rm -rf "$SECRET_DIR"; }

validates() {
  printf '%s' "$2" > "$BATS_TEST_TMPDIR/doc.json"
  json-schema-eval \
    --add-schema "$root/contracts/defs.schema.json" \
    --schema "$root/contracts/$1" \
    --data "$BATS_TEST_TMPDIR/doc.json"
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
  run -1 validates secret-get-response.schema.json '{"found":true,"version":1}'
}

@test "a response claiming not to be found while carrying a value is refused" {
  run -1 validates secret-get-response.schema.json '{"found":false,"version":1,"value":"leaked"}'
}

@test "a request whose signature is ordinary text is accepted" {
  signed=host-privileged
  validates request.schema.json "$(jq -nc --arg signed "$signed" '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}')"
}

@test "a request whose signature carries a control character is refused" {
  signed="host$(printf '\001')privileged"
  run -1 validates request.schema.json "$(jq -nc --arg signed "$signed" '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}')"
}

@test "a request whose signature carries a delete character is refused" {
  signed="host$(printf '\177')privileged"
  run -1 validates request.schema.json "$(jq -nc --arg signed "$signed" '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}')"
}
