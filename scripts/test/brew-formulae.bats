bats_require_minimum_version 1.5.0

setup() {
  root=$ROOT_DIR
  build=$(mktemp -d)
  cp -a "$root/src" "$build/source"
  cp "$root/README.md" "$build/source/README.md"
  VERSION=0.1.0-test PACKAGE_FORMATS=brew bash "$root/scripts/packaging.sh" "$build/source" > /dev/null
  export build root
}

teardown() {
  rm -rf "$build"
}

apt_packages() {
  awk '/^Package: /{print $2}' "$build/source/debian/control" | sort
}

brew_depends_for() {
  awk -F'"' '/depends_on/{print $2}' "$build/source/Formula/$1.rb" | sort
}

@test "a formula exists for every apt package" {
  formulae=$(find "$build/source/Formula" -name '*.rb' -exec basename {} .rb \; | sort)
  [ "$formulae" = "$(apt_packages)" ]
}

@test "every formula's depends_on matches that package's apt Depends exactly" {
  while read -r package; do
    diff <(bash "$root/scripts/apt-depends-for.sh" "$build/source/debian/control" "$package" | sort) <(brew_depends_for "$package")
  done < <(apt_packages)
}

@test "every formula has a non-empty test do block" {
  for formula in "$build"/source/Formula/*.rb; do
    lines=$(sed -n '/^  test do$/,/^  end$/p' "$formula" | sed '1d;$d' | grep -c .)
    [ "$lines" -gt 0 ]
  done
}
