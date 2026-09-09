#!/bin/sh
set -eu

# Builds the packaging. Nothing under debian/ that can be derived is kept: the
# contracts say which packages exist and what each one is, the components say
# which contracts they speak, and the target says what the release being built
# for wants said. debian/control.in carries only what none of those know, which
# is prose about the components themselves.
#
# It runs before dpkg does, on the copy about to be built, because dpkg reads
# debian/control to resolve build dependencies before any rule could act and
# dpkg-source snapshots it before that.
name=$1
source=$2

root=$(CDPATH='' cd "$(dirname "$0")/.." && pwd)
# The target is named on the command line, so its file cannot be followed from
# here. What it may set is the handful of values read just below.
# shellcheck source=/dev/null
. "$root/integration/targets/$name"

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

# The source stanza, as this release wants it stated.
priority_line=""
if [ -n "$PRIORITY" ]; then priority_line="Priority: $PRIORITY\n"; fi
rrr_line=""
if [ -n "$RULES_REQUIRES_ROOT" ]; then rrr_line="Rules-Requires-Root: $RULES_REQUIRES_ROOT\n"; fi

sed -e "s/@COMPAT@/$DEBHELPER_COMPAT/" \
    -e "s|@PRIORITY@|$priority_line|" \
    -e "s/@STANDARDS@/Standards-Version: $STANDARDS_VERSION\n/" \
    -e "s|@RULES_REQUIRES_ROOT@|$rrr_line|" \
    debian/control.in > debian/control

# One package per contract, said by the contract itself.
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
    # ${misc:Depends} is dpkg's substitution variable, written into the control
    # file for dpkg-gencontrol to expand. It is not this shell's to expand.
    # shellcheck disable=SC2016
    printf 'Depends: ${misc:Depends}%b\n' "$needs_defs"
    printf 'Description: token broker for AI agents - the %s contract\n' "$contract"
    jq -r '.description' "$schema" | fold -s -w 78 | sed 's/^/ /; s/[[:space:]]*$//'
  } >> debian/control
done

# What each component speaks, read from what it says. A package that speaks
# none, because it carries no component, gets nothing rather than an empty list.
speaks=$(mktemp)
trap 'rm -f "$speaks"' EXIT
: > "$speaks"

for install in debian/*.install; do
  package=$(basename "$install" .install)
  case $package in gettoken-contract-*) continue ;; esac

  # Which direction a document is carried is a package too: a component that
  # only ever reads one does not install the program that writes one.
  uses=$(
    while read -r src _; do
      if [ -f "$src" ]; then
        grep -ohE '(parse|format) [a-z-]+\.schema\.json' "$src" || true
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
