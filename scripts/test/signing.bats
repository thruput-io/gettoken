bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../.." && pwd)
  work=$(mktemp -d)
  suite=a-branch

  made="$work/made"
  mkdir -p "$made"
  chmod 700 "$made"
  gpg --homedir "$made" --batch --quiet --pinentry-mode loopback --passphrase '' \
    --quick-generate-key 'gettoken archive <archive@gettoken.invalid>' default default never
  ARCHIVE_SIGNING_KEY=$(gpg --homedir "$made" --batch --armor --export-secret-keys)
  minted=$(gpg --homedir "$made" --list-secret-keys --with-colons | awk -F: '/^fpr/ { print $10; exit }')

  packages="$work/packages"
  mkdir -p "$packages/a-package/DEBIAN"
  printf 'Package: a-package\nVersion: 1.0\nSection: misc\nPriority: optional\nArchitecture: all\nMaintainer: nobody <no@one.invalid>\nDescription: one\n' \
    > "$packages/a-package/DEBIAN/control"
  dpkg-deb --build --root-owner-group "$packages/a-package" "$packages" > /dev/null

  export root work suite made minted packages ARCHIVE_SIGNING_KEY
}

teardown() { rm -rf "$work"; }

the_key() { "$root/scripts/signing-key.sh" "$work/key.asc" > /dev/null; }

an_archive() {
  the_key
  "$root/scripts/archive.sh" "$packages" "$work/site" "$suite" "$work/key.asc" > /dev/null
}

@test "the archive signs with the key it was given, not one it invented" {
  the_key
  run "$root/scripts/signing-key.sh" "$work/again.asc"
  [[ "$output" == *"$minted"* ]]
}

@test "an archive with no key to sign with is refused" {
  ARCHIVE_SIGNING_KEY="" run "$root/scripts/signing-key.sh" "$work/key.asc"
  [ "$status" -ne 0 ]
  [[ "$output" == *"no key to sign with"* ]]
}

@test "a key with nowhere to go is refused" {
  run "$root/scripts/signing-key.sh" ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"name the file to write the key to"* ]]
}

@test "the suite is named after the branch, and the packages sit in its pool" {
  an_archive
  run find "$work/site/pool/$suite" -name '*.deb'
  [[ "$output" == *"a-package"* ]]
}

@test "a suite named like a branch, slash and all, gets its own dists and pool" {
  the_key
  "$root/scripts/archive.sh" "$packages" "$work/site" "someone/a-branch" "$work/key.asc" > /dev/null
  run find "$work/site/pool/someone/a-branch" -name '*.deb'
  [[ "$output" == *"a-package"* ]]
  run cat "$work/site/dists/someone/a-branch/Release"
  [[ "$output" == *"Codename: someone/a-branch"* ]]
}

@test "the archive publishes the key a reader verifies it with, carrying no secret half" {
  an_archive
  run grep -c 'BEGIN PGP PRIVATE KEY' "$work/site/gettoken-archive-keyring.asc"
  [ "$output" = "0" ]
  run grep -c 'BEGIN PGP PUBLIC KEY' "$work/site/gettoken-archive-keyring.asc"
  [ "$output" = "1" ]
}

@test "the InRelease it writes verifies against the key the archive publishes" {
  an_archive
  home="$work/reader"
  mkdir -p "$home"
  chmod 700 "$home"
  gpg --homedir "$home" --batch --quiet --import "$work/site/gettoken-archive-keyring.asc"
  run gpg --homedir "$home" --batch --verify "$work/site/dists/$suite/InRelease"
  [[ "$output" == *"Good signature"* ]]
}

@test "a Release changed after signing no longer verifies" {
  an_archive
  home="$work/reader"
  mkdir -p "$home"
  chmod 700 "$home"
  gpg --homedir "$home" --batch --quiet --import "$work/site/gettoken-archive-keyring.asc"
  printf 'Suite: tampered\n' > "$work/site/dists/$suite/Release"
  run gpg --homedir "$home" --batch --verify "$work/site/dists/$suite/Release.gpg" \
    "$work/site/dists/$suite/Release"
  [[ "$output" == *"BAD signature"* ]]
}

@test "the sources file it writes names the suite and carries the key inline" {
  an_archive
  "$root/scripts/sources.sh" "$work/site" "$suite" https://example.invalid/apt
  run cat "$work/site/dists/$suite/gettoken.sources"
  [[ "$output" == *"Suites: $suite"* ]]
  [[ "$output" == *"URIs: https://example.invalid/apt"* ]]
  [[ "$output" == *"Signed-By:"* ]]
  [[ "$output" == *"BEGIN PGP PUBLIC KEY"* ]]
}
