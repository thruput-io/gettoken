#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit

source=${1:?packaging.sh: name the source tree to package}

self_dir=$(dirname "$0")

dpkg_expands_this_one_not_the_shell='$'

needs=$(mktemp)
commands=$(mktemp)
trap 'rm -f "$needs" "$commands"' EXIT
: > "$needs"

install_lists() {
  find "$source/components" "$source/tools" -type f -name '*.install' | sort
}

class_name() {
  awk -F- '{ out = ""; for (i = 1; i <= NF; i++) out = out toupper(substr($i, 1, 1)) substr($i, 2); print out }' <<< "$1"
}

contracts_spoken_in() {
  awk '{
    rest = $0
    while (match(rest, /(parse|format) [a-z-]+\.schema\.json/)) {
      split(substr(rest, RSTART, RLENGTH), spoken, " ")
      sub(/\.schema\.json$/, "", spoken[2])
      print "gettoken-" spoken[1]
      print "gettoken-contract-" spoken[2]
      rest = substr(rest, RSTART + RLENGTH)
    }
  }' "$1"
}

components_piped_into() {
  awk -v commands="$commands" -v this_package="$2" '
    BEGIN {
      while ((getline line < commands) > 0) {
        split(line, installed, " ")
        package_installing[installed[1]] = installed[2]
      }
    }
    {
      rest = $0
      while (match(rest, /\|[[:space:]]*[a-z][a-z-]*/)) {
        piped_into = substr(rest, RSTART, RLENGTH)
        sub(/^\|[[:space:]]*/, "", piped_into)
        if (piped_into in package_installing && package_installing[piped_into] != this_package) {
          print package_installing[piped_into]
        }
        rest = substr(rest, RSTART + RLENGTH)
      }
    }' "$1"
}

needed_by() {
  awk -v want="$1" '$1 == want { for (i = 2; i <= NF; i++) print $i }' "$needs"
}

written_not_built() {
  awk '$1 !~ /^build\// { print $1 }' "$1"
}

must_be_there() {
  if [ ! -f "$source/$2" ]; then
    echo "packaging.sh: $1 names $2, which is not there" >&2
    return 1
  fi
}

stated_by_the_tool() {
  find "$source/components" "$source/tools" -type f -name control.in -exec awk -v want="$1" '
    $1 == "Package:" { package = $2 }
    /^[A-Za-z-]+:/ { depends = ($1 == "Depends:") }
    package == want && depends {
      listed = $0
      sub(/^Depends:/, "", listed)
      sub(/@DEPENDS@:.*$/, "", listed)
      n = split(listed, stated, /[[:space:],]+/)
      for (i = 1; i <= n; i++) if (stated[i] ~ /^[a-z][a-z0-9+.-]*$/) print stated[i]
    }' {} +
}

install_lists | while read -r install; do
  awk -v package="$(basename "$install" .install)" '{ n = split($1, p, "/"); print p[n], package }' "$install"
done > "$commands"

for schema in "$source"/contracts/*.schema.json; do
  contract=$(basename "$schema" .schema.json)
  needs_defs=""
  if [ "$contract" != defs ] && grep -q 'defs\.schema\.json' "$schema"; then
    needs_defs=gettoken-contract-defs
  fi
  printf 'gettoken-contract-%s %s\n' "$contract" "$needs_defs" >> "$needs"
done

install_lists | while read -r install; do
  package=$(basename "$install" .install)
  needed=$(
    written_not_built "$install" | while read -r file; do
      must_be_there "$install" "$file"
      contracts_spoken_in "$source/$file"
      components_piped_into "$source/$file" "$package"
    done | sort -u | tr '\n' ' '
  )
  printf '%s %s\n' "$package" "$needed" >> "$needs"
done

for fmt in ${PACKAGE_FORMATS:?packaging.sh: name the PACKAGE_FORMATS to package for}; do
  case "$fmt" in
    deb)
      rm -rf "$source/debian"
      cp -a "$self_dir/debian" "$source/debian"
      find "$source/components" "$source/tools" -type f \( -name '*.install' -o -name '*.manpages' -o -name '*.docs' -o -name '*.postrm' \) | while read -r said_by_the_tool; do
        cp -p "$said_by_the_tool" "$source/debian/"
      done

      mv "$source/debian/control.in" "$source/debian/control"
      find "$source/components" "$source/tools" -type f -name control.in | sort | while read -r said_by_the_tool; do
        printf '\n'
        cat "$said_by_the_tool"
      done >> "$source/debian/control"

      for schema in "$source"/contracts/*.schema.json; do
        package="gettoken-contract-$(basename "$schema" .schema.json)"
        printf 'contracts/%s usr/share/gettoken/contracts\n' "$(basename "$schema")" > "$source/debian/$package.install"
        {
          printf '\nPackage: %s\nArchitecture: all\n' "$package"
          printf 'Depends: %s{misc:Depends}@DEPENDS@:%s\n' "$dpkg_expands_this_one_not_the_shell" "$package"
          printf 'Description: token broker for AI agents - the %s contract\n' "$(basename "$schema" .schema.json)"
          jq -r '.description' "$schema" | fold -s -w 78 | sed 's/^/ /; s/[[:space:]]*$//'
        } >> "$source/debian/control"
      done

      awk -v needs="$needs" '
        BEGIN {
          while ((getline line < needs) > 0) {
            n = split(line, f, " ")
            list = ""
            for (i = 2; i <= n; i++) list = list ",\n         " f[i]
            managed[f[1]] = list
          }
        }
        {
          where = index($0, "@DEPENDS@:")
          if (where == 0) { print; next }
          printf "%s%s\n", substr($0, 1, where - 1), managed[substr($0, where + length("@DEPENDS@:"))]
        }
      ' "$source/debian/control" > "$source/debian/control.managed"
      mv "$source/debian/control.managed" "$source/debian/control"

      echo "deb: $(grep -c '^Package: ' "$source/debian/control") packages"
      ;;
    brew)
      tap=${BREW_TAP:?packaging.sh: name the BREW_TAP the formulae depend on each other through}
      url=${BREW_URL:?packaging.sh: name the BREW_URL the brew tarball is fetched from}
      sha256=${BREW_SHA256:?packaging.sh: name the BREW_SHA256 of that tarball}

      rm -rf "$source/Formula"
      mkdir "$source/Formula"

      find "$source/components" "$source/tools" -type f -name '*.rb.in' | sort | while read -r said_by_the_tool; do
        package=$(basename "$said_by_the_tool" .rb.in)
        managed=$({ stated_by_the_tool "$package"; needed_by "$package"; } | sort -u | sed "s|.*|  depends_on \"$tap/&\"|")
        export managed
        awk -v url="$url" -v sha256="$sha256" '
          $0 == "@DEPENDS@" { print ENVIRON["managed"]; next }
          { gsub(/@URL@/, url); gsub(/@SHA256@/, sha256); print }
        ' "$said_by_the_tool" | cat -s > "$source/Formula/$package.rb"
      done

      for schema in "$source"/contracts/*.schema.json; do
        package="gettoken-contract-$(basename "$schema" .schema.json)"
        {
          printf 'class %s < Formula\n' "$(class_name "$package")"
          printf '  desc "Token broker for AI agents - %s"\n' "$package"
          printf '  homepage "https://github.com/thruput-io/gettoken"\n'
          printf '  url "%s"\n' "$url"
          printf '  sha256 "%s"\n' "$sha256"
          printf '  license "Apache-2.0"\n\n'
          needed_by "$package" | sed "s|.*|  depends_on \"$tap/&\"|"
          printf '\n  def install\n'
          printf '    (share/"gettoken/contracts").install "contracts/%s"\n' "$(basename "$schema")"
          printf '  end\nend\n'
        } | cat -s > "$source/Formula/$package.rb"
      done

      echo "brew: $(find "$source/Formula" -name '*.rb' | wc -l | tr -d ' ') formulae"
      ;;
    *)
      echo "packaging.sh: no packaging for format '$fmt'" >&2
      exit 1
      ;;
  esac
done
