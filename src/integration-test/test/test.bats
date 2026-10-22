bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

setup() {
  root=$ROOT_DIR
  home=$BATS_TEST_TMPDIR/home
  bin=$BATS_TEST_TMPDIR/installed/bin
  lib=$BATS_TEST_TMPDIR/installed/lib/gettoken
  RECORD_LOG=$BATS_TEST_TMPDIR/recorded
  mkdir -p "$home" "$bin" "$lib"
  touch "$RECORD_LOG"
  export root home bin lib RECORD_LOG
  installed_as "$bin/record" <<'EOF'
printf '%s\n' "$*" >> "$RECORD_LOG"
EOF
  installed_as "$lib/secret-put" <<'EOF'
doc=$(cat)
dir=$HOME/secrets/$(printf '%s' "$doc" | jq -r .key)
mkdir -p "$dir"
printf '%s' "$doc" | jq -r .value > "$dir/0"
EOF
  installed_as "$bin/gettoken" <<'EOF'
test "$1" = integrationtest/ci/run
secret=$(cat "$HOME/secrets/host-privileged/integrationtest/0")
echo "${secret#super-}-ci-run-allowed"
EOF
  installed_as "$bin/integration-test-tool" <<'EOF'
echo "${INTEGRATIONTEST_TOKEN%-ci-run-allowed}"
EOF
}

running() {
  HOME=$home PATH="$bin:$PATH" ROOT_DIR=$root INSTALL_COMMAND="record install" REMOVE_PACKAGES="record remove" "$root/src/integration-test/test.sh"
}

running_without() {
  HOME=$home PATH="$bin:$PATH" ROOT_DIR=$root INSTALL_COMMAND="record install" REMOVE_PACKAGES="record remove" env -u "$1" "$root/src/integration-test/test.sh"
}

carried_in() {
  printf '%s' "$1" | sed -n 's/^carried=//p'
}

report_of() {
  printf '^installed=integration-test-tool\n%b$' "$1"
}

@test "the run reports the super-token it put and what the tool ran on, as the same thing" {
  run -0 --separate-stderr running
  expected=$(report_of 'carried=([0-9a-f]{32})\nran_on=([0-9a-f]{32})')
  [[ "$output" =~ $expected ]]
  [ "${BASH_REMATCH[1]}" = "${BASH_REMATCH[2]}" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
  [ "$(cat "$RECORD_LOG")" = "$(printf 'install integration-test-tool\nremove')" ]
  [ ! -e "$home/secrets/host-privileged/integrationtest" ]
}

@test "the tool running on something else fails the run, and says what was put and what ran" {
  installed_as "$bin/integration-test-tool" <<'EOF'
echo not-what-was-put
EOF
  run -1 --separate-stderr running
  expected=$(report_of 'carried=[0-9a-f]{32}\nran_on=not-what-was-put')
  [[ "$output" =~ $expected ]]
  assert_equal "$(without_kcov_trace "$stderr")" "integration-test: integrationtest/ci/run ran on 'not-what-was-put', not on the '$(carried_in "$output")' that was put in the store"
}

@test "the packages are removed and the store purged even when the run fails" {
  installed_as "$bin/integration-test-tool" <<'EOF'
echo not-what-was-put
EOF
  run -1 --separate-stderr running
  [ "$(cat "$RECORD_LOG")" = "$(printf 'install integration-test-tool\nremove')" ]
  [ ! -e "$home/secrets/host-privileged/integrationtest" ]
}

@test "a tool that cannot run leaves the report short, fails the run with its own words, and is still removed" {
  installed_as "$bin/integration-test-tool" <<'EOF'
echo "integration-test-tool: boom" >&2; exit 3
EOF
  run -3 --separate-stderr running
  expected=$(report_of 'carried=[0-9a-f]{32}')
  [[ "$output" =~ $expected ]]
  assert_equal "$(without_kcov_trace "$stderr")" "integration-test-tool: boom"
  [ "$(cat "$RECORD_LOG")" = "$(printf 'install integration-test-tool\nremove')" ]
  [ ! -e "$home/secrets/host-privileged/integrationtest" ]
}

@test "naming no INSTALL_COMMAND is refused before anything is installed" {
  run -1 --separate-stderr running_without INSTALL_COMMAND
  [ "$output" = "" ]
  [[ "$(without_kcov_trace "$stderr")" == *": INSTALL_COMMAND: test.sh: name the INSTALL_COMMAND" ]]
  [ "$(cat "$RECORD_LOG")" = "" ]
}

@test "naming no REMOVE_PACKAGES is refused before anything is installed" {
  run -1 --separate-stderr running_without REMOVE_PACKAGES
  [ "$output" = "" ]
  [[ "$(without_kcov_trace "$stderr")" == *": REMOVE_PACKAGES: test.sh: name the REMOVE_PACKAGES command" ]]
  [ "$(cat "$RECORD_LOG")" = "" ]
}
