bats_require_minimum_version 1.5.0

setup() {
  root=$ROOT_DIR
  workflow=$root/.github/workflows/verifications.yml
  export root workflow
}

line_of() {
  grep -n -- "$1" "$2" | cut -d: -f1
}

scripts_handed_to_a_shell_that_do_not_start_by_stopping_on_failure() {
  awk -v quote="'" '
    BEGIN { opened = -1 }
    NR == opened + 1 && $0 !~ /^[[:space:]]*set -eu$/ { print "line " NR ": " $0 }
    $0 ~ ("c " quote "$") { opened = NR }
  ' "$root/agent_build.sh"
}

places_the_reports_to_carry_out_are_listed() {
  grep -rl 'build/\*\.tap' "$root/.github"
}

@test "the build is told the command that adds what was built as a package source" {
  run -0 --separate-stderr bash "$root/dynamic.sh"
  [ "$(printf '%s\n' "$output" | grep -c '^export ADD_ARCHIVE$')" = "1" ]
}

@test "make test adds what was built as a package source before it installs from it" {
  [ "$(line_of 'ADD_ARCHIVE' "$root/Makefile")" -lt "$(line_of 'src/integration-test/test.sh' "$root/Makefile")" ]
}

@test "the command that adds a package source is written in one place" {
  run -1 grep -l -E 'sources\.list\.d|brew tap-new' "$root/Makefile" "$root/agent_build.sh" "$workflow" "$root/CONTRIBUTING.md"
  [ "$output" = "" ]
}

@test "every script agent_build.sh hands to a shell starts by stopping on failure" {
  run -0 scripts_handed_to_a_shell_that_do_not_start_by_stopping_on_failure
  [ "$output" = "" ]
}

@test "no script agent_build.sh hands to a shell chains commands, where a failure early in the chain is passed over" {
  run -1 grep -n -E '^    .*&&' "$root/agent_build.sh"
  [ "$output" = "" ]
}

@test "the tree agent_build.sh streams holds every path once, so unpacking it does not fail" {
  [ "$(grep -c -- 'tar -cf - --no-recursion -T -' "$root/agent_build.sh")" = "1" ]
}

@test "the release job holds the distribution token before it creates the release" {
  [ "$(line_of 'actions/create-github-app-token' "$workflow")" -lt "$(line_of 'gh release create' "$workflow")" ]
}

@test "the distribution repositories are listed once" {
  [ "$(grep -c 'homebrew-tap' "$workflow")" = "1" ]
}

@test "the reports a build carries out of the run are listed once" {
  run -0 places_the_reports_to_carry_out_are_listed
  [ "$output" = "$root/.github/actions/upload-reports/action.yml" ]
}
