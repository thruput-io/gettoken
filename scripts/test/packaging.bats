bats_require_minimum_version 1.5.0

setup() {
  root=$ROOT_DIR
  export root
}

install_lists() {
  find "$root/src" -type f -name '*.install' | sort
}

installed_into() {
  install_lists | xargs awk -v want="$1" '$2 == want { n = split($1, p, "/"); print p[n] }' | sort
}

destinations() {
  install_lists | xargs awk '{ print $2 }' | sort -u
}

destinations_reachable_without_gettoken_on_path() {
  destinations | grep -vxE 'usr/bin|usr/lib/gettoken(/.*)?|usr/share/gettoken(/.*)?'
}

packaged_as() {
  cp -R "$root/src" "$BATS_TEST_TMPDIR/source"
  PACKAGE_FORMATS=$1 BREW_TAP=the/tap bash "$root/scripts/packaging.sh" "$BATS_TEST_TMPDIR/source" file:///the/tarball.tar.gz the-checksum > /dev/null
}

packages_of_the_components() {
  sed -n 's/^Package: //p' "$BATS_TEST_TMPDIR/source/debian/control" | grep -v '^gettoken-contract-' | sort
}

needed_by_the_package() {
  awk -v want="$1" '
    $1 == "Package:" { package = $2 }
    /^[A-Za-z-]+:/ { depends = ($1 == "Depends:") }
    package == want && depends { listed = $0; sub(/^Depends:/, "", listed); gsub(/[[:space:],]+/, "\n", listed); print listed }
  ' "$BATS_TEST_TMPDIR/source/debian/control" | grep -vE '^$|^\$|^gettoken-(contract-|parse$|format$)' | sort
}

needed_by_the_formula() {
  sed -n 's|^  depends_on "the/tap/\(.*\)"$|\1|p' "$BATS_TEST_TMPDIR/source/Formula/$1.rb" | grep -vE '^gettoken-(contract-|parse$|format$)' | sort
}

@test "the agent's entry point and the tool are the only names on a public PATH" {
  [ "$(installed_into usr/bin)" = "$(printf 'gettoken\nintegration-test-tool')" ]
}

@test "everything else the packaging installs is off a public PATH" {
  run -1 destinations_reachable_without_gettoken_on_path
  [ "$output" = "" ]
}

@test "the exchanger is not something an agent can run" {
  [ "$(installed_into usr/bin)" = "$(installed_into usr/bin | grep -v integrationtest)" ]
  grep -q 'usr/lib/gettoken/exchangers' "$root/src/tools/integration-test-tool/integration-test-tool-exchanger.install"
}

@test "the control file is assembled from what every tool says of its own packages" {
  packaged_as deb
  run -0 packages_of_the_components
  [ "$output" = "$(printf '%s\n' gettoken gettoken-entitlements gettoken-exchanger gettoken-format gettoken-parse gettoken-secret-manager gettoken-token-requester gettoken-token-service integration-test-tool integration-test-tool-exchanger)" ]
}

@test "a package depends on the packages whose components its own pipe a document into" {
  packaged_as deb
  run -0 needed_by_the_package gettoken
  [ "$output" = "gettoken-token-requester" ]
  run -0 needed_by_the_package gettoken-token-requester
  [ "$output" = "$(printf 'gettoken-entitlements\ngettoken-token-service')" ]
  run -0 needed_by_the_package gettoken-token-service
  [ "$output" = "gettoken-exchanger" ]
  run -0 needed_by_the_package gettoken-exchanger
  [ "$output" = "gettoken-secret-manager" ]
}

@test "the tool depends on gettoken and on its own exchanger, as the tool itself says" {
  packaged_as deb
  run -0 needed_by_the_package integration-test-tool
  [ "$output" = "$(printf 'gettoken\nintegration-test-tool-exchanger')" ]
}

@test "a plugin depends on the exchanger it plugs into, as the tool itself says, and on nothing else" {
  packaged_as deb
  run -0 needed_by_the_package integration-test-tool-exchanger
  [ "$output" = "gettoken-exchanger" ]
}

@test "the formulae depend on each other as the packages do" {
  packaged_as brew
  run -0 needed_by_the_formula gettoken
  [ "$output" = "gettoken-token-requester" ]
  run -0 needed_by_the_formula gettoken-token-requester
  [ "$output" = "$(printf 'gettoken-entitlements\ngettoken-token-service')" ]
  run -0 needed_by_the_formula gettoken-token-service
  [ "$output" = "gettoken-exchanger" ]
  run -0 needed_by_the_formula gettoken-exchanger
  [ "$output" = "gettoken-secret-manager" ]
  run -0 needed_by_the_formula integration-test-tool
  [ "$output" = "$(printf 'gettoken\nintegration-test-tool-exchanger')" ]
  run -0 needed_by_the_formula integration-test-tool-exchanger
  [ "$output" = "gettoken-exchanger" ]
}

@test "a formula is the tool's own brew file, pointed at the tarball it was built from" {
  packaged_as brew
  [ "$(sed -n 's/^  url "\(.*\)"$/\1/p' "$BATS_TEST_TMPDIR/source/Formula/gettoken.rb")" = "file:///the/tarball.tar.gz" ]
  [ "$(sed -n 's/^  sha256 "\(.*\)"$/\1/p' "$BATS_TEST_TMPDIR/source/Formula/gettoken.rb")" = "the-checksum" ]
  run -1 grep -l '@[A-Z_]*@' "$BATS_TEST_TMPDIR/source/Formula"/*.rb
  [ "$output" = "" ]
}

@test "every contract is a formula of its own" {
  packaged_as brew
  [ "$(find "$BATS_TEST_TMPDIR/source/Formula" -name 'gettoken-contract-*.rb' | wc -l | tr -d ' ')" = "$(find "$root/src/contracts" -name '*.schema.json' | wc -l | tr -d ' ')" ]
}
