bats_require_minimum_version 1.5.0

setup() {
  root=$ROOT_DIR
  there=$BATS_TEST_TMPDIR/there
  home=$BATS_TEST_TMPDIR/home
  built=$BATS_TEST_TMPDIR/source
  stubs=$BATS_TEST_TMPDIR/stubs
  cp -R "$root/src" "$built"
  mkdir -p "$stubs" "$home"
  CONTRACTS_DIR="$root/src/contracts"
  export root there home built stubs CONTRACTS_DIR
}

built_for() {
  make -s -C "$built" "$@" > /dev/null
}

installed_as() {
  printf '%s\n' '#!/bin/sh' 'set -eu' "$2" > "$1"
  chmod 755 "$1"
}

asking_gettoken() {
  "$built/tools/gettoken/bin/gettoken" integrationtest/ci/run
}

asking_the_exchanger() {
  jq -nc '{who:"tore",wants:"integrationtest/ci/run"}' \
    | PATH="$stubs:$root/build/bin:$PATH" "$built/components/exchanger/exchanger"
}

putting_a_secret() {
  jq -nc '{key:"host-privileged/integrationtest",value:"super-sample"}' \
    | HOME="$home" PATH="$root/build/bin:$PATH" "$built/components/secret-manager/secret-put"
}

getting_the_secret() {
  jq -nc '{key:"host-privileged/integrationtest"}' \
    | HOME="$home" PATH="$root/build/bin:$PATH" "$built/components/secret-manager/secret-get" --with-key
}

parsing_without_being_told_where_contracts_are() {
  jq -nc '{wants:"integrationtest/ci/run"}' \
    | env -u CONTRACTS_DIR "$built/build/bin/parse" agent-capability-request.schema.json wants
}

directory_named_in() {
  sed -n "$2" "$built/$1"
}

@test "gettoken runs the privileged half in the library directory it was built for" {
  built_for configured "prefix=$there"
  mkdir -p "$there/lib/gettoken"
  cp "$root/build/bin/format" "$there/lib/gettoken/format"
  installed_as "$there/lib/gettoken/token-requester" 'cat > /dev/null; echo "the token-requester in the library directory ran"'
  run -0 asking_gettoken
  [ "$output" = "the token-requester in the library directory ran" ]
}

@test "the exchanger runs the plugins in the library directory it was built for" {
  built_for configured "prefix=$there"
  mkdir -p "$there/lib/gettoken/exchangers"
  installed_as "$there/lib/gettoken/exchangers/integrationtest" 'cat > /dev/null; echo from-the-library-directory'
  installed_as "$stubs/secret-get" 'version=0; value=super-sample; export version value; format secret-get-response.schema.json version value'
  run -0 asking_the_exchanger
  [ "$(printf '%s' "$output" | jq -r '.access_token')" = "from-the-library-directory" ]
}

@test "the store is kept under the home of whoever runs it, whatever the build was told" {
  built_for configured "prefix=$there"
  run -0 putting_a_secret
  [ "$(cat "$home/secrets/host-privileged/integrationtest/0")" = "super-sample" ]
  run -0 getting_the_secret
  [ "$(printf '%s' "$output" | jq -r '.value')" = "super-sample" ]
  [ ! -e "$there/var" ]
}

@test "parse reads the contracts in the data directory it was built for" {
  built_for contract "prefix=$there"
  mkdir -p "$there/share/gettoken"
  cp -R "$root/src/contracts" "$there/share/gettoken/contracts"
  run -0 parsing_without_being_told_where_contracts_are
  [ "$output" = "wants='integrationtest/ci/run'" ]
}

@test "built for /usr, the components look where Debian installs" {
  built_for configured prefix=/usr
  [ "$(directory_named_in tools/gettoken/bin/gettoken 's|^PATH="\([^:]*\):.*|\1|p')" = "/usr/lib/gettoken" ]
  [ "$(directory_named_in components/exchanger/exchanger 's|^plugins=.*:-\(.*\)}$|\1|p')" = "/usr/lib/gettoken/exchangers" ]
  [ "$(directory_named_in components/contract/contract.go 's|^[[:space:]]*return "\(.*/contracts\)"$|\1|p')" = "/usr/share/gettoken/contracts" ]
}

@test "a built tree leaves no directory undecided" {
  built_for configured "prefix=$there"
  run -1 grep -rlE '@(libdir|datadir)@' "$built/tools" "$built/components"
  [ "$output" = "" ]
}
