bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

setup() {
  root=$ROOT_DIR
  STORE_DIR=$(mktemp -d)
  PATH="$STORE_DIR:$root/src/components/exchanger:$root/build/bin:$PATH"
  EXCHANGER_DIR=$(mktemp -d)
  CONTRACTS_DIR="$root/src/contracts"
  ASKED_FILE="$STORE_DIR/asked"
  ARGS_FILE="$STORE_DIR/args"
  RAN_FILE="$STORE_DIR/the-plugin-ran"
  export PATH EXCHANGER_DIR CONTRACTS_DIR ASKED_FILE ARGS_FILE RAN_FILE
  holding super-sample-token-123
}

teardown() { rm -rf "$EXCHANGER_DIR" "$STORE_DIR"; }

holding() {
  STORED=$1
  export STORED
  cat > "$STORE_DIR/secret-get" <<'STUB'
#!/bin/sh
set -eu
printf '%s' "$*" > "$ARGS_FILE"
cat > "$ASKED_FILE"
version=0
value=$STORED
export version value
format secret-get-response.schema.json version value
STUB
  chmod 755 "$STORE_DIR/secret-get"
}

holding_nothing() {
  printf '%s\n' '#!/bin/sh' 'echo "secret-get: nothing is stored under the key" >&2' 'exit 1' > "$STORE_DIR/secret-get"
  chmod 755 "$STORE_DIR/secret-get"
}

plugged_in() {
  printf '%s\n' '#!/bin/sh' "$2" > "$EXCHANGER_DIR/$1"
  chmod 755 "$EXCHANGER_DIR/$1"
}

exchanging() {
  jq -nc --arg wants "$1" '{who:"tore",wants:$wants}' | exchanger
}

@test "the plugin installed for the first segment is told the whole capability" {
  plugged_in integrationtest 'cat > /dev/null; echo "$1"'
  run -0 --separate-stderr exchanging integrationtest/ci/run
  [ "$(printf '%s' "$output" | jq -r '.access_token')" = "integrationtest/ci/run" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "the plugin is handed the secret the store holds for its service on standard input" {
  holding super-9b1e
  plugged_in integrationtest 'cat'
  run -0 --separate-stderr exchanging integrationtest/ci/run
  [ "$(printf '%s' "$output" | jq -r '.access_token')" = "super-9b1e" ]
}

@test "what the plugin writes is the token, and it lives two minutes" {
  plugged_in integrationtest 'cat > /dev/null; echo narrow-token'
  run -0 --separate-stderr exchanging integrationtest/ci/run
  [ "$(printf '%s' "$output" | jq -c -S .)" = '{"access_token":"narrow-token","expires_in":120}' ]
}

@test "the store is asked for the key the service is keyed by, and for no version" {
  plugged_in integrationtest 'cat > /dev/null; echo narrow-token'
  run -0 --separate-stderr exchanging integrationtest/ci/run
  [ "$(jq -r '.key' < "$ASKED_FILE")" = "host-privileged/integrationtest" ]
  [ "$(cat "$ARGS_FILE")" = "--with-key" ]
}

@test "a service the store holds nothing for hands over nothing, and its plugin never runs" {
  holding_nothing
  plugged_in integrationtest 'touch "$RAN_FILE"; echo narrow-token'
  run -1 --separate-stderr exchanging integrationtest/ci/run
  [ "$output" = "" ]
  [ ! -f "$RAN_FILE" ]
}

@test "a capability no plugin serves is refused before the store is asked" {
  run -1 --separate-stderr exchanging nosuch/capability
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "exchanger: no plugin serves nosuch/capability"
  [ ! -f "$ASKED_FILE" ]
}

@test "a plugin that fails takes the request down, and says so" {
  plugged_in integrationtest 'exit 1'
  run -1 --separate-stderr exchanging integrationtest/ci/run
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "exchanger: the plugin serving integrationtest/ci/run failed"
}

@test "a plugin that writes nothing hands over nothing" {
  plugged_in integrationtest 'cat > /dev/null'
  run -1 --separate-stderr exchanging integrationtest/ci/run
  [ "$output" = "" ]
}

@test "a capability whose first segment climbs out of the plugin directory never reaches the lookup" {
  run -1 --separate-stderr exchanging ../../bin/sh
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy exchange-request.schema.json\nvalidating https://thruput.io/gettoken/exchange-request.schema.json: validating /properties/wants: validating /$defs/Capability: pattern: "../../bin/sh" does not match regular expression "^[a-z0-9-]+(/[a-z0-9._-]+)+$"')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
  [ ! -f "$ASKED_FILE" ]
}
