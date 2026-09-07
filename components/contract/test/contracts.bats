bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH= cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/components/contract:$PATH"
  CONTRACTS_DIR="$root/contracts"
  export PATH CONTRACTS_DIR
}

admits() { printf '%s' "$2" | validate "$1"; }

@test "a secret-get response claiming to be found without a value is refused" {
  run -1 --separate-stderr admits secret-get-response.schema.json '{"found":true,"version":1}'
}

@test "a secret-get response claiming not to be found while carrying a value is refused" {
  run -1 --separate-stderr admits secret-get-response.schema.json '{"found":false,"version":1,"value":"leaked"}'
}

@test "a request whose signature is ordinary text is admitted" {
  admits request.schema.json "$(jq -nc '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:"host-privileged"}')"
}

@test "a request whose signature carries a control character is refused" {
  signed="host$(printf '\001')privileged"
  run -1 --separate-stderr admits request.schema.json "$(jq -nc --arg signed "$signed" '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}')"
}

@test "a request whose signature carries a delete character is refused" {
  signed="host$(printf '\177')privileged"
  run -1 --separate-stderr admits request.schema.json "$(jq -nc --arg signed "$signed" '{who:"tore",doing:"mac.lan",wants:"integrationtest/ci/run",signed:$signed}')"
}
