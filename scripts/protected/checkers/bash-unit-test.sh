#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "$(dirname "$0")/common.sh"

report=${1:?bash-unit-test.sh: name the report to check}

tests=$(stat 'bats tests')
skip=$(awk '/^ok .* # skip/ { n++ } END { print n + 0 }' "$report")
pass=$(awk '/^ok / && !/ # skip/ { n++ } END { print n + 0 }' "$report")
fail=$(awk '/^not ok / { n++ } END { print n + 0 }' "$report")
echo "bats: $pass passed, $fail failed, $skip skipped of $tests @test in the repo (min $BATS_MIN_PASSED passed, max $BATS_MAX_SKIPPED skipped)"
[ "$fail" -eq 0 ] && [ "$skip" -le "$BATS_MAX_SKIPPED" ] && [ "$pass" -eq "$tests" ] && [ "$pass" -ge "$BATS_MIN_PASSED" ]
