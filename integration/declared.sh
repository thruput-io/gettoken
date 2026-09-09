#!/bin/sh
set -eu

# What a built package declares it may be told, against what its executables
# actually say. The packaging is generated from the second, so this cannot
# disagree unless the generation or the build lost something on the way — which
# is the only reason to read it back off the artefact rather than off the
# source it came from.
built=$1
source=$2

spoken=$(mktemp)
declared=$(mktemp)
trap 'rm -f "$spoken" "$declared"' EXIT

wrong=0

for deb in "$built"/*.deb; do
  package=$(dpkg-deb -f "$deb" Package)
  case $package in
    gettoken-contract-*|gettoken-parse|gettoken-format|*-dbgsym) continue ;;
  esac

  install="$source/debian/$package.install"
  if [ ! -f "$install" ]; then continue; fi

  while read -r src _; do
    if [ -f "$source/$src" ]; then
      grep -ohE '(parse|format) [a-z-]+\.schema\.json' "$source/$src" || true
    fi
  done < "$install" | awk '{print $2}' | sed 's/\.schema\.json$//' | sort -u > "$spoken"

  dpkg-deb -f "$deb" Depends | tr ',' '\n' | sed 's/^ *//' \
    | sed -n 's/^gettoken-contract-//p' | sort -u > "$declared"

  missing=$(comm -23 "$spoken" "$declared" | tr '\n' ' ' | sed 's/ *$//')
  spare=$(comm -13 "$spoken" "$declared" | tr '\n' ' ' | sed 's/ *$//')

  if [ -n "$missing" ]; then
    echo "FAIL: $package speaks $missing but the built package does not depend on the contract for it"
    wrong=1
  fi
  if [ -n "$spare" ]; then
    echo "FAIL: $package depends on $spare but never speaks it, so it may be told more than it needs"
    wrong=1
  fi
  if [ -z "$missing$spare" ]; then
    echo "ok: $package speaks exactly what it depends on"
  fi
done

if [ "$wrong" -ne 0 ]; then exit 1; fi
