bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH= cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/components/token-service:$PATH"
  EXCHANGER_DIR=$(mktemp -d)
  export PATH EXCHANGER_DIR
}

teardown() { rm -rf "$EXCHANGER_DIR"; }

register() {
  printf '%s\n' '#!/bin/sh' "$2" > "$EXCHANGER_DIR/$1"
  chmod 755 "$EXCHANGER_DIR/$1"
}

@test "the exchanger registered for the first segment is handed the whole capability" {
  register integrationtest 'printf "%s\n120\n" "$1"'
  run --separate-stderr sh -c 'printf %s "{\"wants\":\"integrationtest/ci/run\"}" | token-service'
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r '.access_token')" = "integrationtest/ci/run" ]
  [ "$(printf '%s' "$output" | jq -r '.expires_in')" = "120" ]
}

@test "a request naming no capability is refused" {
  run -1 --separate-stderr sh -c 'printf %s "{}" | token-service'
  [ "$output" = "" ]
}

@test "a capability no exchanger serves is refused" {
  run -1 --separate-stderr sh -c 'printf %s "{\"wants\":\"nosuch/capability\"}" | token-service'
  [ "$output" = "" ]
}

@test "a capability whose first segment climbs out of the exchanger directory is refused" {
  run -1 --separate-stderr sh -c 'printf %s "{\"wants\":\"../../bin/sh\"}" | token-service'
  [ "$output" = "" ]
}

@test "a capability whose first segment names the exchanger directory itself is refused" {
  run -1 --separate-stderr sh -c 'printf %s "{\"wants\":\"./ci/run\"}" | token-service'
  [ "$output" = "" ]
}

@test "an exchanger returning no lifetime is refused" {
  register integrationtest 'printf "%s\n" narrow-token'
  run -1 --separate-stderr sh -c 'printf %s "{\"wants\":\"integrationtest/ci/run\"}" | token-service'
  [ "$output" = "" ]
}

@test "an exchanger that fails takes the request down with it" {
  register integrationtest 'exit 1'
  run -1 --separate-stderr sh -c 'printf %s "{\"wants\":\"integrationtest/ci/run\"}" | token-service'
  [ "$output" = "" ]
}
