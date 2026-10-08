#!/usr/bin/env bash
set -euo pipefail

root=${1:?inventory.sh: name the repository to list}
report=${2:?inventory.sh: name the inventory to write}

linter_of() {
  local file=$1 name=${1##*/} first
  case "$file" in
    */vendor/*) echo unlinted; return ;;
    .github/workflows/*.yml) echo workflow; return ;;
    .github/actions/*/action.yml) echo action; return ;;
  esac
  case "$name" in
    *.schema.json) echo schema; return ;;
    *.json) echo json; return ;;
    *.go|go.mod) echo go; return ;;
    *.env) echo env; return ;;
    *.sh|*.bash|*.bats) echo shell; return ;;
    Makefile|GNUmakefile|makefile) echo make; return ;;
    *.mk) echo make-fragment; return ;;
  esac
  first=$(head -n 1 "$file")
  case "$first" in
    '#!'*make*) echo make ;;
    '#!'*sh|'#!'*bats) echo shell ;;
    *) echo unlinted ;;
  esac
}

cd "$root"
git ls-files --cached --others --exclude-standard | sort -u | while IFS= read -r file; do
  [ -f "$file" ] && printf '%s\t%s\n' "$(linter_of "$file")" "$file"
done > "$report.new"
if cmp -s "$report.new" "$report"; then
  rm "$report.new"
else
  mv "$report.new" "$report"
fi
