bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  STUB_DIR=$(mktemp -d)
  PATH="$STUB_DIR:$root/tools/integration-test-tool/privileged/exchangers:$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/contracts"
  ASKED_FILE="$STUB_DIR/asked"
  ARGS_FILE="$STUB_DIR/args"
  export PATH CONTRACTS_DIR ASKED_FILE ARGS_FILE
}

teardown() { rm -rf "$STUB_DIR"; }

holding() {
  STORED=$1
  export STORED
  cat > "$STUB_DIR/secret-get" <<'STUB'
#!/bin/sh
set -eu
printf '%s' "$*" > "$ARGS_FILE"
cat > "$ASKED_FILE"
version=0
value=$STORED
export version value
format secret-get-response.schema.json version value
STUB
  chmod 755 "$STUB_DIR/secret-get"
}

trading() {
  printf '%s' "{\"who\":\"tore\",\"wants\":\"$1\"}" | integrationtest
}

@test "the narrow token carries what the store holds, not what the exchanger expected" {
  holding super-4f2a9c
  run -0 --separate-stderr trading integrationtest/ci/run
  [ "$(printf '%s' "$output" | jq -r '.access_token')" = "4f2a9c-ci-run-allowed" ]
  [ "$stderr" = "" ]
}

@test "a different super-token yields a different narrow token" {
  holding super-9b1e
  run -0 --separate-stderr trading integrationtest/ci/run
  [ "$(printf '%s' "$output" | jq -r '.access_token')" = "9b1e-ci-run-allowed" ]
}

@test "the token it issues lives two minutes" {
  holding super-4f2a9c
  run -0 --separate-stderr trading integrationtest/ci/run
  [ "$(printf '%s' "$output" | jq -r '.expires_in')" = "120" ]
}

@test "it asks the store for the key it is keyed by, and for no version" {
  holding super-4f2a9c
  run -0 --separate-stderr trading integrationtest/ci/run
  [ "$(jq -r '.key' < "$ASKED_FILE")" = "host-privileged/integrationtest" ]
  [ "$(cat "$ARGS_FILE")" = "--with-key" ]
}

@test "a stored value that is not a super-token is refused, and hands over nothing" {
  holding not-a-super-token
  run -1 --separate-stderr trading integrationtest/ci/run
  [ "$output" = "" ]
  [ "$stderr" = "integrationtest: the stored super-token is not one this exchanger can trade" ]
}

@test "a stored value that is only the prefix is refused" {
  holding super-
  run -1 --separate-stderr trading integrationtest/ci/run
  [ "$output" = "" ]
}

@test "a capability it does not serve is refused before the store is touched" {
  holding super-4f2a9c
  run -1 --separate-stderr trading github/thruput-io/gettoken/pr/create
  [ "$output" = "" ]
  [ ! -f "$ASKED_FILE" ]
}

@test "a request carrying what an exchanger may not see is refused by the contract" {
  holding super-4f2a9c
  run -1 --separate-stderr sh -c 'printf "%s" "{\"who\":\"tore\",\"wants\":\"integrationtest/ci/run\",\"signed\":\"host-privileged\"}" | integrationtest'
  [ "$output" = "" ]
}
