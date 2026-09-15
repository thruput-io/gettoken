bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../.." && pwd)
  work=$(mktemp -d)
  signing="$work/signing"
  archive="$work/archive"
  mkdir -p "$archive"
  printf 'Suite: testing\nCodename: testing\nDate: Sun, 14 Sep 2026 00:00:00 +0000\n' \
    > "$archive/Release"
  export root work signing archive
}

teardown() { rm -rf "$work"; }

a_key() { "$root/scripts/signing-key.sh" "$signing" > /dev/null; }

a_signed_archive() { a_key; "$root/scripts/sign.sh" "$archive" "$signing" > /dev/null; }

verified_against_the_published_key() {
  home="$work/verifier"
  mkdir -p "$home"
  chmod 700 "$home"
  GNUPGHOME="$home" gpg --batch --quiet --import "$signing/pubkey.gpg"
  GNUPGHOME="$home" gpg --batch --verify "$@" 2>&1
}

@test "the key it generates is named by a forty-digit fingerprint" {
  a_key
  run cat "$signing/fingerprint"
  [[ "$output" =~ ^[0-9A-F]{40}$ ]]
}

@test "the public key it exports is the key the fingerprint names" {
  a_key
  home="$work/reader"
  mkdir -p "$home"
  chmod 700 "$home"
  run env GNUPGHOME="$home" gpg --batch --quiet --with-colons --show-keys "$signing/pubkey.gpg"
  [[ "$output" == *"$(cat "$signing/fingerprint")"* ]]
}

@test "the public key it exports carries no secret half" {
  a_key
  run grep -c 'BEGIN PGP PRIVATE KEY' "$signing/pubkey.gpg"
  [ "$output" = "0" ]
}

@test "signing leaves the Release it signed untouched" {
  before=$(cat "$archive/Release")
  a_signed_archive
  [ "$(cat "$archive/Release")" = "$before" ]
}

@test "signing writes an InRelease carrying the Release inline" {
  a_signed_archive
  run head -1 "$archive/InRelease"
  [ "$output" = "-----BEGIN PGP SIGNED MESSAGE-----" ]
  run grep -c '^Codename: testing$' "$archive/InRelease"
  [ "$output" = "1" ]
}

@test "the InRelease it writes verifies against the key it exported" {
  a_signed_archive
  run verified_against_the_published_key "$archive/InRelease"
  [[ "$output" == *"Good signature"* ]]
}

@test "the detached signature it writes verifies against the Release" {
  a_signed_archive
  run verified_against_the_published_key "$archive/Release.gpg" "$archive/Release"
  [[ "$output" == *"Good signature"* ]]
}

@test "a Release changed after signing no longer verifies" {
  a_signed_archive
  printf 'Suite: tampered\n' > "$archive/Release"
  run verified_against_the_published_key "$archive/Release.gpg" "$archive/Release"
  [[ "$output" == *"BAD signature"* ]]
}

@test "publishing names the archive and the key apt must verify against" {
  a_signed_archive
  run "$root/scripts/publish.sh" "$archive" "$signing/pubkey.gpg" "$work/gettoken.list"
  [ "$status" -eq 0 ]
  run cat "$work/gettoken.list"
  [ "$output" = "deb [signed-by=$signing/pubkey.gpg] file:$archive ./" ]
}

@test "publishing an archive that was never signed is refused" {
  rm -f "$archive/InRelease"
  run "$root/scripts/publish.sh" "$archive" "$signing/pubkey.gpg" "$work/gettoken.list"
  [ "$status" -ne 0 ]
  [ ! -e "$work/gettoken.list" ]
}

@test "generating a key with nowhere to put it is refused before anything is removed" {
  run "$root/scripts/signing-key.sh" ""
  [ "$status" -ne 0 ]
  [[ "$output" == *"no directory to write the key into"* ]]
}

@test "generating a key twice into the same directory replaces it" {
  a_key
  first=$(cat "$signing/fingerprint")
  a_key
  second=$(cat "$signing/fingerprint")
  [ "$first" != "$second" ]
  [[ "$second" =~ ^[0-9A-F]{40}$ ]]
}
