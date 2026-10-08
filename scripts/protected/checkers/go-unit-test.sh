#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "$(dirname "$0")/common.sh"

report=${1:?go-unit-test.sh: name the report to check}

tests=$(stat 'go tests')
top='select(.Test != null and (.Test | contains("/") | not))'
pass=$(jq -s "[.[] | $top | select(.Action == \"pass\")] | length" "$report")
fail=$(jq -s "[.[] | select(.Action == \"fail\")] | length" "$report")
skip=$(jq -s "[.[] | select(.Action == \"skip\" and .Test != null)] | length" "$report")
echo "go test: $pass passed, $fail failed, $skip skipped of $tests func Test in the repo (min $GO_TEST_MIN_PASSED passed, max $GO_TEST_MAX_SKIPPED skipped)"
[ "$fail" -eq 0 ] && [ "$skip" -le "$GO_TEST_MAX_SKIPPED" ] && [ "$pass" -eq "$tests" ] && [ "$pass" -ge "$GO_TEST_MIN_PASSED" ]
