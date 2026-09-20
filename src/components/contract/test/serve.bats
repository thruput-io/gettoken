bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../../.." && pwd)
  PATH="$root/build/bin:$PATH"
  CONTRACTS_DIR="$root/src/contracts"
  DOOR=$(mktemp -d)/example
  export PATH CONTRACTS_DIR DOOR
}

teardown() { rm -rf "$(dirname "$DOOR")"; }

behind() {
  printf '%s\n' '#!/bin/bash' 'set -euo pipefail' "$1" > "$DOOR.answers"
  chmod 755 "$DOOR.answers"
}

storing() {
  behind 'cat > /dev/null; printf "%s\n" "{\"version\":0,\"value\":\"super-1\"}"'
  printf '%s\n' '#!/bin/bash' 'set -euo pipefail' \
    'exec serve --request secret-put-request.schema.json --response secret-put-response.schema.json --answers "$0.answers" -- "$@"' \
    > "$DOOR"
  chmod 755 "$DOOR"
}

put='{"key":"johans-laptop/github","value":"super-1"}'

@test "a payload given as an argument is answered on standard output" {
  storing
  run -0 --separate-stderr "$DOOR" "$put"
  [ "$output" = '{"version":0,"value":"super-1"}' ]
  [ "$stderr" = "" ]
}

@test "the same payload taken from standard input is answered the same way" {
  storing
  run -0 --separate-stderr sh -c 'printf %s "$1" | "$DOOR" --stdin' sh "$put"
  [ "$output" = '{"version":0,"value":"super-1"}' ]
}

@test "a file named by the caller takes the answer, closed to everyone but its owner" {
  storing
  run -0 --separate-stderr "$DOOR" -f "$(dirname "$DOOR")/answer.json" "$put"
  [ "$output" = "" ]
  [ "$(cat "$(dirname "$DOOR")/answer.json")" = '{"version":0,"value":"super-1"}' ]
  run -0 --separate-stderr find "$(dirname "$DOOR")/answer.json" -perm 600
  [ "$output" = "$(dirname "$DOOR")/answer.json" ]
}

@test "what a caller says cannot describe the door it is reaching" {
  storing
  run -1 --separate-stderr "$DOOR" --answers /bin/sh --request token-request.schema.json
  [ "$output" = "" ]
  [[ "$stderr" == example:* ]]
}

@test "what answers is told the shape that admitted the ask" {
  behind 'cat > /dev/null; printf "{\"version\":0,\"value\":\"%s\"}\n" "$REQUEST_CONTRACT"'
  printf '%s\n' '#!/bin/bash' 'set -euo pipefail' \
    'exec serve --request secret-get-request.schema.json --request secret-get-request-version.schema.json --response secret-get-response.schema.json --answers "$0.answers" -- "$@"' \
    > "$DOOR"
  chmod 755 "$DOOR"
  run -0 --separate-stderr "$DOOR" '{"key":"johans-laptop/github"}'
  [ "$(printf '%s' "$output" | jq -r '.value')" = "secret-get-request.schema.json" ]
  run -0 --separate-stderr "$DOOR" '{"key":"johans-laptop/github","version":0}'
  [ "$(printf '%s' "$output" | jq -r '.value')" = "secret-get-request-version.schema.json" ]
}

@test "a component that fails hands its own status out, and says why itself" {
  behind 'cat > /dev/null; echo "example: the store is not there" >&2; exit 4'
  printf '%s\n' '#!/bin/bash' 'set -euo pipefail' \
    'exec serve --request secret-put-request.schema.json --response secret-put-response.schema.json --answers "$0.answers" -- "$@"' \
    > "$DOOR"
  chmod 755 "$DOOR"
  run -4 --separate-stderr "$DOOR" "$put"
  [ "$output" = "" ]
  [ "$stderr" = "example: the store is not there" ]
}
