bats_require_minimum_version 1.5.0

setup() {
  root=$ROOT_DIR
  build=$(mktemp -d)
  cp -a "$root/src" "$build/source"
  bash "$root/scripts/packaging.sh" "$build/source" > /dev/null
  VERSION=0.0.0 BREW_TAP=thruput-io/brew bash "$root/scripts/brew-formulae.sh" \
    "$build/source" "$build/Formula" https://example.invalid/gettoken.tar.gz 0 > /dev/null
  export build root
}

teardown() {
  rm -rf "$build"
}

apt_packages() {
  awk '/^Package: / { print $2 }' "$build/source/debian/control" | sort
}

apt_depends_of() {
  awk -v want="$1" '
    /^Package: / { pkg = $2; depends = 0; next }
    /^Depends:/ { depends = 1; sub(/^Depends: */, "") }
    depends && /^[A-Z][A-Za-z-]*:/ && !/^Depends:/ { depends = 0 }
    depends && pkg == want { gsub(/[ ,]+/, "\n"); print }
  ' "$build/source/debian/control" | grep -E '^(gettoken|integration-test-tool)' | sort
}

brew_depends_of() {
  awk -F'"' '/depends_on "thruput-io\/brew\// { sub(/.*\//, "", $2); print $2 }' "$build/Formula/$1.rb" | sort
}

@test "a formula exists for every apt package and for nothing else" {
  formulae=$(find "$build/Formula" -name '*.rb' -exec basename {} .rb \; | sort)
  [ "$formulae" = "$(apt_packages)" ]
}

@test "every formula depends on exactly what its apt package depends on" {
  while read -r package; do
    diff <(apt_depends_of "$package") <(brew_depends_of "$package")
  done < <(apt_packages)
}

@test "the graph has edges, so the mirror is not only a count" {
  edges=$(cat "$build"/Formula/*.rb | grep -c 'depends_on "thruput-io/brew/')
  [ "$edges" -gt 22 ]
}
