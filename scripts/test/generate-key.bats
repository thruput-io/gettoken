bats_require_minimum_version 1.5.0

setup() {
  root="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "generate-key emits an armored GPG secret key block" {
  run "$root/scripts/generate-key.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"BEGIN PGP PRIVATE KEY BLOCK"* ]]
  [[ "$output" == *"END PGP PRIVATE KEY BLOCK"* ]]
}
