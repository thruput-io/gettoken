#!/bin/sh
set -eu

# A contract is a package, and a component depends on the contracts it speaks.
# That is only true if it stays true, so it is read back out of the source: the
# schemas each executable names, the package that ships it, and what that
# package declares. No package is built and nothing is installed to know this.
root=$1
control="$root/debian/control"

spoken=$(mktemp)
declared=$(mktemp)
trap 'rm -f "$spoken" "$declared"' EXIT

wrong=0

for install in "$root"/debian/*.install; do
  pkg=$(basename "$install" .install)
  case $pkg in
    gettoken-contract-*|gettoken-parse|gettoken-format) continue ;;
  esac

  while read -r src _; do
    [ -f "$root/$src" ] || continue
    grep -ohE '(parse|format) [a-z-]+\.schema\.json' "$root/$src" || true
  done < "$install" | awk '{print $2}' | sed 's/\.schema\.json$//' | sort -u > "$spoken"

  awk -v p="Package: $pkg" '
    $0 == p { inpkg = 1; next }
    /^Package: / { inpkg = 0 }
    inpkg && /gettoken-contract-/ { gsub(/[ ,]/, ""); print }
  ' "$control" | sed 's/^gettoken-contract-//' | sort -u > "$declared"

  missing=$(comm -23 "$spoken" "$declared" | tr '\n' ' ' | sed 's/ *$//')
  spare=$(comm -13 "$spoken" "$declared" | tr '\n' ' ' | sed 's/ *$//')

  if [ -n "$missing" ]; then
    echo "FAIL: $pkg speaks $missing but does not depend on the contract for it"
    wrong=1
  fi
  if [ -n "$spare" ]; then
    echo "FAIL: $pkg depends on $spare but never speaks it, so it may be told more than it needs"
    wrong=1
  fi
  [ -n "$missing$spare" ] || echo "ok: $pkg speaks exactly what it depends on"
done

[ "$wrong" -eq 0 ] || exit 1
