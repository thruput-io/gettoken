bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../../.." && pwd)
  PATH="$root/components/secret-manager:$root/build/bin:$PATH"
  SECRET_DIR="$(mktemp -d)/secrets"
  CONTRACTS_DIR="$root/contracts"
  export PATH SECRET_DIR CONTRACTS_DIR
}

teardown() { rm -rf "$(dirname "$SECRET_DIR")"; }

putting() {
  printf '%s' "$2" \
    | format secret-put-request.schema.json "key=$1" value@- \
    | secret-put
}

getting() {
  if [ $# -eq 2 ]; then
    format secret-get-request.schema.json "key=$1" "version=$2" | secret-get
  else
    format secret-get-request.schema.json "key=$1" | secret-get
  fi
}

@test "the first secret stored under a key is version zero" {
  putting johans-laptop/github super-1
  run -0 --separate-stderr getting johans-laptop/github
  [ "$(printf '%s' "$output" | jq -r '.version')" = "0" ]
  [ "$(printf '%s' "$output" | jq -r '.value')" = "super-1" ]
}

@test "the store gives each secret the next version, so no caller chooses one" {
  putting johans-laptop/github super-1
  putting johans-laptop/github super-2
  run -0 --separate-stderr getting johans-laptop/github
  [ "$(printf '%s' "$output" | jq -r '.version')" = "1" ]
  [ "$(printf '%s' "$output" | jq -r '.value')" = "super-2" ]
}

@test "storing a secret again never replaces the one already there" {
  putting johans-laptop/github super-1
  putting johans-laptop/github super-2
  run -0 --separate-stderr getting johans-laptop/github 0
  [ "$(printf '%s' "$output" | jq -r '.value')" = "super-1" ]
}

@test "asking for a version that does not exist yet is an answer, not a failure" {
  putting johans-laptop/github super-1
  run -0 --separate-stderr getting johans-laptop/github 1
  [ "$(printf '%s' "$output" | jq -r '.found')" = "false" ]
  [ "$(printf '%s' "$output" | jq -r '.version')" = "0" ]
  [ "$(printf '%s' "$output" | jq -r 'has("value")')" = "false" ]
}

@test "what secret-get emits when it finds the secret carries the value and says so" {
  putting johans-laptop/github super-1
  run -0 --separate-stderr getting johans-laptop/github
  [ "$(printf '%s' "$output" | jq -r '.found')" = true ]
  [ "$(printf '%s' "$output" | jq -r '.version')" = 0 ]
  [ "$(printf '%s' "$output" | jq -r '.value')" = super-1 ]
}

@test "the secret never appears on stderr" {
  putting johans-laptop/github super-1
  run -0 --separate-stderr getting johans-laptop/github
  [ "$stderr" = "" ]
}

@test "nothing stored under a key is a failure, not an empty answer" {
  run -1 --separate-stderr getting nobody/nothing
  [ "$output" = "" ]
  [[ "$stderr" == *"nothing is stored under nobody/nothing"* ]]
}

@test "a key the contract does not admit is refused" {
  run -1 --separate-stderr sh -c \
    'printf %s "{\"key\":\"Johans-Laptop\",\"value\":\"super-1\"}" | secret-put'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-put-request.schema.json"* ]]
}

@test "a key climbing out of the store is refused, because a key carries no dots" {
  run -1 --separate-stderr sh -c \
    'printf %s "{\"key\":\"..\",\"value\":\"super-1\"}" | secret-put'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-put-request.schema.json"* ]]
  [ ! -e "$(dirname "$SECRET_DIR")/github" ]
}

@test "storing a secret with no value is refused" {
  run -1 --separate-stderr sh -c \
    'printf %s "{\"key\":\"johans-laptop/github\",\"value\":\"\"}" | secret-put'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-put-request.schema.json"* ]]
}

@test "asking with no key at all is refused" {
  run -1 --separate-stderr sh -c 'printf %s "{}" | secret-get'
  [ "$output" = "" ]
  [[ "$stderr" == *"does not satisfy secret-get-request.schema.json"* ]]
}

@test "every directory the store is made of is closed to everyone but its owner" {
  putting johans-laptop/github super-1
  run -0 --separate-stderr find "$SECRET_DIR" -type d -perm 700
  [ "$(printf '%s\n' "$output" | sort)" = "$(printf '%s\n' "$SECRET_DIR" "$SECRET_DIR/johans-laptop" "$SECRET_DIR/johans-laptop/github" | sort)" ]
}

@test "the stored secret is closed to everyone but its owner" {
  putting johans-laptop/github super-1
  run -0 --separate-stderr find "$SECRET_DIR" -type f -perm 600
  [ "$output" = "$SECRET_DIR/johans-laptop/github/0" ]
}
