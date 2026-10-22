bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

setup() {
  root=$ROOT_DIR
  probe=$BATS_TEST_TMPDIR/probe.mk
  export root probe
}

recipe() {
  printf 'probe:\n\t@%s\n' "$1" > "$probe"
  make -s -f "$root/Makefile" -f "$probe" probe
}

recipe_under_make() {
  printf 'probe:\n\t@echo survived\n' > "$probe"
  make -s -f "$root/Makefile" -f "$probe" "MAKE_VERSION=$1" probe
}

@test "a recipe stops at the first command that fails" {
  run -2 --separate-stderr recipe 'false; echo survived'
  [ "$output" = "" ]
}

@test "a command substitution that fails fails the recipe" {
  run -2 --separate-stderr recipe 'n=$$(false); echo survived'
  [ "$output" = "" ]
}

@test "a command that fails inside a pipe fails the recipe" {
  run -2 --separate-stderr recipe 'false | cat; echo survived'
  [ "$output" = "" ]
}

@test "a variable that was never set fails the recipe" {
  run -2 --separate-stderr recipe 'echo "$$nothing_was_set_here"; echo survived'
  [ "$output" = "" ]
}

@test "a recipe that holds prints what it says" {
  run -0 --separate-stderr recipe 'echo held'
  [ "$output" = "held" ]
}

@test "a make older than 4 is refused before any recipe runs" {
  run -2 --separate-stderr recipe_under_make 3.81
  [ "$output" = "" ]
  [[ "$stderr" == *"GNU make 4 or later is required, found 3.81"* ]]
}
