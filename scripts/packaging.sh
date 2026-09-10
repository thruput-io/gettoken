#!/bin/bash
set -euo pipefail

name=$1
source=$2

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
# shellcheck source=/dev/null
. "$root/scripts/targets/$name"

carried_compat=$(dpkg-query -W -f='${Version}' debhelper | sed 's/[.~].*//')
if [ "$carried_compat" != "$DEBHELPER_COMPAT" ]; then
  echo "packaging.sh: $name says debhelper $DEBHELPER_COMPAT, this base carries $carried_compat" >&2
  exit 1
fi

carried_go=$(go version | sed 's/.*go\([0-9]*\.[0-9]*\).*/\1/')
if [ "$carried_go" != "$GO_VERSION" ]; then
  echo "packaging.sh: $name says go $GO_VERSION, this base carries $carried_go" >&2
  exit 1
fi

cd "$source"

sed -i "s/^go [0-9]*\.[0-9]*$/go $GO_VERSION/" components/contract/go.mod

priority_line=""
if [ -n "$PRIORITY" ]; then priority_line="Priority: $PRIORITY\n"; fi
rrr_line=""
if [ -n "$RULES_REQUIRES_ROOT" ]; then rrr_line="Rules-Requires-Root: $RULES_REQUIRES_ROOT\n"; fi

sed -e "s/@COMPAT@/$DEBHELPER_COMPAT/" \
    -e "s|@PRIORITY@|$priority_line|" \
    -e "s/@STANDARDS@/Standards-Version: $STANDARDS_VERSION\n/" \
    -e "s|@RULES_REQUIRES_ROOT@|$rrr_line|" \
    debian/control.in > debian/control

dpkg_expands_this_one_not_the_shell='$'

for schema in contracts/*.schema.json; do
  contract=$(basename "$schema" .schema.json)
  package="gettoken-contract-$contract"

  printf '%s usr/share/gettoken/contracts\n' "$schema" > "debian/$package.install"

  needs_defs=""
  if [ "$contract" != defs ] && grep -q 'defs\.schema\.json' "$schema"; then
    needs_defs=",\n         gettoken-contract-defs"
  fi

  {
    printf '\nPackage: %s\nArchitecture: all\n' "$package"
    printf 'Depends: %s{misc:Depends}%b\n' "$dpkg_expands_this_one_not_the_shell" "$needs_defs"
    printf 'Description: token broker for AI agents - the %s contract\n' "$contract"
    jq -r '.description' "$schema" | fold -s -w 78 | sed 's/^/ /; s/[[:space:]]*$//'
  } >> debian/control
done

speaks=$(mktemp)
trap 'rm -f "$speaks"' EXIT
: > "$speaks"

every_contract_named_on_a_line() {
  awk '{
    rest = $0
    while (match(rest, /(parse|format) [a-z-]+\.schema\.json/)) {
      print substr(rest, RSTART, RLENGTH)
      rest = substr(rest, RSTART + RLENGTH)
    }
  }' "$1"
}

for install in debian/*.install; do
  package=$(basename "$install" .install)
  case $package in gettoken-contract-*) continue ;; esac

  uses=$(
    while read -r src _; do
      if [ -f "$src" ]; then
        every_contract_named_on_a_line "$src"
      fi
    done < "$install"
  )
  needs=$(
    printf '%s\n' "$uses" \
      | awk 'NF { print "gettoken-" $1; sub(/\.schema\.json$/, "", $2); print "gettoken-contract-" $2 }' \
      | sort -u | tr '\n' ' '
  )
  printf '%s %s\n' "$package" "$needs" >> "$speaks"
done

awk -v speaks="$speaks" '
  BEGIN {
    while ((getline line < speaks) > 0) {
      n = split(line, f, " ")
      key = f[1]
      list = ""
      for (i = 2; i <= n; i++) list = list ",\n         " f[i]
      have[key] = list
    }
  }
  {
    where = index($0, "@CONTRACTS@:")
    if (where == 0) { print; next }
    head = substr($0, 1, where - 1)
    key = substr($0, where + length("@CONTRACTS@:"))
    printf "%s%s\n", head, have[key]
  }
' debian/control > debian/control.spliced
mv debian/control.spliced debian/control

echo "built as $name: debhelper $DEBHELPER_COMPAT, go $GO_VERSION, Policy $STANDARDS_VERSION, $(grep -c '^Package: ' debian/control) packages"
