bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

setup() {
  root=$ROOT_DIR
  STORE_DIR=$(mktemp -d)
  PATH="$STORE_DIR:$root/src/tools/integration-test-tool/privileged/exchangers:$PATH"
  STORE_ASKED_FILE="$STORE_DIR/the-store-was-asked"
  export PATH STORE_ASKED_FILE
  cat > "$STORE_DIR/secret-get" <<'STUB'
#!/bin/sh
set -eu
touch "$STORE_ASKED_FILE"
exit 1
STUB
  chmod 755 "$STORE_DIR/secret-get"
}

teardown() { rm -rf "$STORE_DIR"; }

trading() {
  printf '%s' "$2" | integrationtest "$1"
}

@test "the narrow token carries the secret it was handed, not what the plugin expected" {
  run -0 --separate-stderr trading integrationtest/ci/run super-sample-token-123
  [ "$output" = "sample-token-123-ci-run-allowed" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "a different super-token yields a different narrow token" {
  run -0 --separate-stderr trading integrationtest/ci/run super-9b1e
  [ "$output" = "9b1e-ci-run-allowed" ]
}

@test "it trades what it was handed and never asks the store" {
  run -0 --separate-stderr trading integrationtest/ci/run super-sample-token-123
  [ "$output" = "sample-token-123-ci-run-allowed" ]
  [ ! -f "$STORE_ASKED_FILE" ]
}

@test "a secret that is not a super-token is refused, and hands over nothing" {
  run -1 --separate-stderr trading integrationtest/ci/run not-a-super-token
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "integrationtest: the secret it was handed is not a super-token it can trade"
}

@test "a secret that is only the prefix is refused" {
  run -1 --separate-stderr trading integrationtest/ci/run super-
  [ "$output" = "" ]
}

@test "a capability it does not serve is refused" {
  run -1 --separate-stderr trading github/thruput-io/gettoken/pr/create super-sample-token-123
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "integrationtest: nothing is registered for github/thruput-io/gettoken/pr/create"
}
