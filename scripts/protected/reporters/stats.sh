#!/usr/bin/env bash
set -euo pipefail

inventory=${1:?stats.sh: name the inventory to count}

count() {
  awk -F'\t' -v linter="$1" -v path="$2" -v except="$3" \
    '$1 == linter && $2 ~ path && $2 !~ except { n++ } END { print n + 0 }' "$inventory"
}

lines() {
  awk -F'\t' -v linter="$1" -v path="$2" -v pattern="$3" '
    $1 == linter && $2 ~ path { while ((getline line < $2) > 0) if (line ~ pattern) n++; close($2) }
    END { print n + 0 }' "$inventory"
}

echo "shell files: $(count shell . '^$')"
echo "make files: $(count make . '^$')"
echo "make fragments: $(count make-fragment . '^$')"
echo "go source files: $(count go '\.go$' '_test\.go$')"
echo "go test files: $(count go '_test\.go$' '^$')"
echo "go tests: $(lines go '_test\.go$' '^func Test')"
echo "json schemas: $(count schema . '^$')"
echo "json files: $(count json . '^$')"
echo "workflow files: $(count workflow . '^$')"
echo "action files: $(count action . '^$')"
echo "bats test files: $(count shell '\.bats$' '^$')"
echo "bats tests: $(lines shell '\.bats$' '^@test')"
echo "bash coverage sources: $(count shell '^src/' '\.bats$')"
echo "unlinted files: $(count unlinted . '^$')"
