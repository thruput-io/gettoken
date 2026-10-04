bats_require_minimum_version 1.5.0

setup() {
  root=$ROOT_DIR
  build=$(mktemp -d)
  cp -a "$root/src" "$build/source"
  bash "$root/scripts/packaging.sh" "$build/source" > /dev/null
  VERSION=0.0.0 BREW_TAP=thruput-io/tap bash "$root/scripts/brew-formulae.sh" \
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
  awk -F'"' '/depends_on "thruput-io\/tap\// { sub(/.*\//, "", $2); print $2 }' "$build/Formula/$1.rb" | sort
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
  edges=$(cat "$build"/Formula/*.rb | grep -c 'depends_on "thruput-io/tap/')
  [ "$edges" -gt 22 ]
}

debian_paths_installed() {
  for install in "$build"/source/debian/*.install; do
    package=$(basename "$install" .install)
    awk '/^build\/bin\// { built = 1 } $1 !~ /^build\// { print $1 } END { print (built ? "components/contract/contract.go" : "") }' "$install" \
      | awk NF | while read -r file; do
          grep -oF -e /usr/lib/gettoken -e /usr/share/gettoken -e /var/lib/gettoken "$build/source/$file" \
            | sort -u | sed "s|^|$package $file |"
        done
  done | sort
}

debian_paths_rewritten() {
  for formula in "$build"/Formula/*.rb; do
    awk -F'"' -v package="$(basename "$formula" .rb)" '/^    inreplace / { print package, $2, $4 }' "$formula"
  done | sort
}

@test "no formula installs a file that still names a Debian path" {
  [ -n "$(debian_paths_installed)" ]
  diff <(debian_paths_installed) <(debian_paths_rewritten)
}
