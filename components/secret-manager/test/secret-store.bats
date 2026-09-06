bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH= cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/components/secret-manager:$root/components/contract:$PATH"
  SECRET_DIR=$(mktemp -d)
  export PATH SECRET_DIR
}

teardown() { rm -rf "$SECRET_DIR"; }

@test "a stored secret comes back with its version" {
  printf 'super-1' | secret-put '{"holder":"johans-laptop","service":"github","version":1}'
  run --separate-stderr secret-get '{"holder":"johans-laptop","service":"github"}'
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r '.version')" = "1" ]
  [ "$(printf '%s' "$output" | jq -r '.value')" = "super-1" ]
}

@test "the newest version is the one returned" {
  printf 'super-1' | secret-put '{"holder":"johans-laptop","service":"github","version":1}'
  printf 'super-2' | secret-put '{"holder":"johans-laptop","service":"github","version":2}'
  run --separate-stderr secret-get '{"holder":"johans-laptop","service":"github"}'
  [ "$(printf '%s' "$output" | jq -r '.version')" = "2" ]
  [ "$(printf '%s' "$output" | jq -r '.value')" = "super-2" ]
}

@test "asking for a version that exists returns exactly it" {
  printf 'super-1' | secret-put '{"holder":"johans-laptop","service":"github","version":1}'
  printf 'super-2' | secret-put '{"holder":"johans-laptop","service":"github","version":2}'
  run --separate-stderr secret-get '{"holder":"johans-laptop","service":"github","version":1}'
  [ "$(printf '%s' "$output" | jq -r '.value')" = "super-1" ]
}

@test "asking for a version that does not exist yet is an answer, not a failure" {
  printf 'super-1' | secret-put '{"holder":"johans-laptop","service":"github","version":1}'
  run --separate-stderr secret-get '{"holder":"johans-laptop","service":"github","version":2}'
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r '.found')" = "false" ]
  [ "$(printf '%s' "$output" | jq -r '.version')" = "1" ]
  [ "$(printf '%s' "$output" | jq -r 'has("value")')" = "false" ]
}

@test "the secret never appears on stderr" {
  printf 'super-1' | secret-put '{"holder":"johans-laptop","service":"github","version":1}'
  run --separate-stderr secret-get '{"holder":"johans-laptop","service":"github"}'
  [ "$stderr" = "" ]
}

@test "putting a version that already exists is refused" {
  printf 'super-1' | secret-put '{"holder":"johans-laptop","service":"github","version":1}'
  run -1 --separate-stderr sh -c 'printf other | secret-put "{\"holder\":\"johans-laptop\",\"service\":\"github\",\"version\":1}"' 
  run --separate-stderr secret-get '{"holder":"johans-laptop","service":"github"}'
  [ "$(printf '%s' "$output" | jq -r '.value')" = "super-1" ]
}

@test "nothing stored is a failure, not an empty answer" {
  run -1 --separate-stderr secret-get '{"holder":"nobody","service":"nothing"}'
  [ "$output" = "" ]
}

@test "secret-put refuses a document its contract forbids" {
  run -1 --separate-stderr secret-put '{"holder":"johans-laptop","service":"GitHub","version":1}'
}

@test "secret-get refuses a document its contract forbids" {
  run -1 --separate-stderr secret-get '{"holder":"johans-laptop"}'
}
