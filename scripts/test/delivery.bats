bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export root
}

@test "delivering with nowhere to put the packages is refused before anything is removed" {
  run "$root/scripts/deliver.sh" deb-testing ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"no directory to deliver the packages into"* ]]
}
