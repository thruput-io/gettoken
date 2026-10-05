bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

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

a_copy_of_the_source() {
  cp -R "$root/src" "$BATS_TEST_TMPDIR/source"
}

packaging_for() {
  PACKAGE_FORMATS=$1 BREW_TAP=the/tap BREW_URL=file:///the/tarball.tar.gz BREW_SHA256=the-checksum \
    bash "$root/scripts/packaging.sh" "$BATS_TEST_TMPDIR/source"
}

packaged_as() {
  a_copy_of_the_source
  packaging_for "$1" > /dev/null
}

packaging_for_deb_when_a_packaging_file_cannot_be_copied() {
  mkdir "$BATS_TEST_TMPDIR/stubs"
  printf '%s\n' '#!/bin/sh' 'set -eu' 'test "$1" != -p' 'exec /bin/cp "$@"' > "$BATS_TEST_TMPDIR/stubs/cp"
  chmod 755 "$BATS_TEST_TMPDIR/stubs/cp"
  PATH="$BATS_TEST_TMPDIR/stubs:$PATH" packaging_for deb
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

@test "what a tool says it needs it says once, in its control file, and its formula follows" {
  a_copy_of_the_source
  sed -i.before 's/^         gettoken,$/         gettoken-entitlements,/' "$BATS_TEST_TMPDIR/source/tools/integration-test-tool/control.in"
  packaging_for brew > /dev/null
  run -0 needed_by_the_formula integration-test-tool
  [ "$output" = "$(printf 'gettoken-entitlements\nintegration-test-tool-exchanger')" ]
}

@test "an install list naming a file that is not there stops the packaging, even ahead of one that is" {
  a_copy_of_the_source
  printf '%s\n' 'components/exchanger/not-there usr/lib/gettoken' 'components/exchanger/exchanger usr/lib/gettoken' \
    > "$BATS_TEST_TMPDIR/source/components/exchanger/gettoken-exchanger.install"
  run -1 --separate-stderr packaging_for deb
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "packaging.sh: components/exchanger/gettoken-exchanger.install names components/exchanger/not-there, which is not there"
}

@test "a packaging file that cannot be copied stops the packaging" {
  a_copy_of_the_source
  run -1 --separate-stderr packaging_for_deb_when_a_packaging_file_cannot_be_copied
  [ "$output" = "" ]
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
