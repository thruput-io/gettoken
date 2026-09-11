bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export root
  suite=test-branch/test-target

  refused=$BATS_TEST_TMPDIR/refused
  git -C "$root" rev-parse --is-inside-work-tree > /dev/null 2>"$refused" || {
    echo "git cannot read $root, so every rule below would read nothing" >&2
    cat "$refused" >&2
    return 1
  }
}

# These rules govern the product. CONTRIBUTING puts exploratory/ outside it:
# it answers a question rather than guarding anything, and make test does not
# run it, so what it reaches for is not what ships.
searched() {
  git -C "$root" grep -In "$1" -- ":!scripts/test/archive.bats" ":!exploratory"
}

armored_secret_key() {
  home=$BATS_TEST_TMPDIR/mint
  mkdir -p "$home"
  chmod 700 "$home"
  gpg --homedir "$home" --batch --quiet --pinentry-mode loopback --passphrase '' \
      --quick-generate-key 'gettoken archive test <archive@example.com>' \
      default default never
  gpg --homedir "$home" --batch --quiet --armor --export-secret-keys
}

a_package_to_index() {
  built=$BATS_TEST_TMPDIR/probe
  mkdir -p "$built/DEBIAN" "$1"
  printf 'Package: probe\nVersion: 1\nArchitecture: all\nMaintainer: gettoken <archive@example.com>\nDescription: a package for the index to hold\n' \
    > "$built/DEBIAN/control"
  dpkg-deb --build "$built" "$1/probe.deb" > /dev/null
}

indexed_with() {
  key_as_the_workflow_writes_it=$BATS_TEST_TMPDIR/signing-key.asc
  printf '%s' "$1" > "$key_as_the_workflow_writes_it"
  packages=$BATS_TEST_TMPDIR/packages
  archive=$BATS_TEST_TMPDIR/archive
  a_package_to_index "$packages"
  "$root/scripts/archive.sh" "$packages" "$archive" "$suite" "$key_as_the_workflow_writes_it"
}

@test "nothing installs from an archive apt was told to trust without checking" {
  run ! searched 'trusted=yes'
}

@test "nothing writes the stanza that says where the archive is" {
  run ! searched '> */etc/apt/sources.list'
}

@test "no versioned file pins the archive to one processor architecture" {
  run ! searched '\(amd64\|arm64\|x86_64\|aarch64\)'
}

# bats test_tags=debian
@test "the index is built for the architecture the machine actually is" {
  this_machine=$(dpkg --print-architecture)
  indexed_with "$(armored_secret_key)"
  run cat "$archive/dists/$suite/main/binary-$this_machine/Packages"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Package: probe"* ]]
}

# bats test_tags=debian
@test "the release names that same architecture to apt" {
  this_machine=$(dpkg --print-architecture)
  indexed_with "$(armored_secret_key)"
  run grep '^Architectures:' "$archive/dists/$suite/Release"
  [ "$status" -eq 0 ]
  [ "$output" = "Architectures: $this_machine" ]
}

# bats test_tags=debian
@test "the signing key survives being written the way the workflow writes it" {
  indexed_with "$(armored_secret_key)"
  checker=$BATS_TEST_TMPDIR/checker
  mkdir -p "$checker"
  chmod 700 "$checker"
  gpg --homedir "$checker" --batch --quiet --import "$archive/gettoken-archive-keyring.asc"
  run gpg --homedir "$checker" --batch --verify \
    "$archive/dists/$suite/Release.gpg" "$archive/dists/$suite/Release"
  [ "$status" -eq 0 ]
}

# bats test_tags=debian
@test "a signing key whose lines were collapsed is refused, not quietly skipped" {
  collapsed=$(armored_secret_key | tr -d '\n')
  run indexed_with "$collapsed"
  [ "$status" -ne 0 ]
}

@test "the site root is left free for what debian is not" {
  run ! grep -n '\$pages/dists\|\$pages/pool' \
    "$root/scripts/publish.sh" "$root/scripts/unpublish.sh"
}
