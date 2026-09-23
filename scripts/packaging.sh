#!/usr/bin/env bash
set -euo pipefail

source=$1

cd "$source"

cp debian/control.in debian/control

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

for fmt in ${PACKAGE_FORMATS:-deb}; do
  case "$fmt" in
    deb)
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

      echo "built $(grep -c '^Package: ' debian/control) packages"
      ;;
    brew)
      echo "packaging for brew format"
      ;;
  esac
done
