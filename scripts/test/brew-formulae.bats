bats_require_minimum_version 1.5.0

setup() {
  root=$ROOT_DIR
  build=$(mktemp -d)
  cp -a "$root/src" "$build/source"
  cp "$root/README.md" "$build/source/README.md"
  PACKAGE_FORMATS=deb bash "$root/scripts/packaging.sh" "$build/source" > /dev/null
  VERSION=0.1.0-test PACKAGE_FORMATS=brew bash "$root/scripts/packaging.sh" "$build/source" > /dev/null
  export build
}

teardown() {
  rm -rf "$build"
}

apt_packages() {
  awk '/^Package: /{print $2}' "$build/source/debian/control" | sort
}

apt_depends_for() {
  awk -v pkg="$1" '
    /^Package: / { in_pkg = ($2 == pkg) }
    in_pkg && /^Depends:/ {
      indep = 1
      line = $0
      sub(/^Depends: */, "", line)
      collect(line)
      next
    }
    in_pkg && indep && /^(Architecture|Description): / { indep = 0 }
    in_pkg && indep { collect($0) }
    function collect(s,    n, parts, i, tok) {
      n = split(s, parts, ",")
      for (i = 1; i <= n; i++) {
        tok = parts[i]
        gsub(/^[ \t]+|[ \t]+$/, "", tok)
        if (tok ~ /^(gettoken|integration-test-tool)/) print tok
      }
    }
  ' "$build/source/debian/control" | sort
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
    diff <(apt_depends_for "$package") <(brew_depends_for "$package")
  done < <(apt_packages)
}

@test "every formula has a non-empty test do block" {
  for formula in "$build"/source/Formula/*.rb; do
    awk '/^  test do$/{f=1;next} /^  end$/{if(f){c++}} END{exit !(c>=1)}' "$formula" \
      || { echo "no test do in $formula"; return 1; }
    lines=$(awk '/^  test do$/{f=1;next} /^  end$/{f=0} f' "$formula" | grep -c .)
    [ "$lines" -gt 0 ]
  done
}
