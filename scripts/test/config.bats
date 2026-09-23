bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export root
  source "$root/constants.env"
}

@test "DEBIAN_BUILD_DEPS contains python3-check-jsonschema" {
  [[ " $DEBIAN_BUILD_DEPS " == *" python3-check-jsonschema "* ]]
}

@test "DARWIN_BUILD_DEPS contains check-jsonschema" {
  [[ " $DARWIN_BUILD_DEPS " == *" check-jsonschema "* ]]
}
