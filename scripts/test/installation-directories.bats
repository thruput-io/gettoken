bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/helper"

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
  run -0 --separate-stderr asking_gettoken
  [ "$output" = "the token-requester in the library directory ran" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "the exchanger runs the plugins in the library directory it was built for" {
  built_for configured "prefix=$there"
  mkdir -p "$there/lib/gettoken/exchangers"
  installed_as "$there/lib/gettoken/exchangers/integrationtest" 'cat > /dev/null; echo from-the-library-directory'
  installed_as "$stubs/secret-get" 'version=0; value=super-sample; export version value; format secret-get-response.schema.json version value'
  run -0 --separate-stderr asking_the_exchanger
  [ "$output" = '{"access_token":"from-the-library-directory","expires_in":120}' ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "the store is kept under the home of whoever runs it, whatever the build was told" {
  built_for configured "prefix=$there"
  run -0 --separate-stderr putting_a_secret
  [ "$output" = '{"value":"super-sample","version":0}' ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
  [ "$(cat "$home/secrets/host-privileged/integrationtest/0")" = "super-sample" ]
  run -0 --separate-stderr getting_the_secret
  [ "$output" = '{"value":"super-sample","version":0}' ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
  [ ! -e "$there/var" ]
}

@test "parse reads the contracts in the data directory it was built for" {
  built_for contract "prefix=$there"
  mkdir -p "$there/share/gettoken"
  cp -R "$root/src/contracts" "$there/share/gettoken/contracts"
  run -0 --separate-stderr parsing_without_being_told_where_contracts_are
  [ "$output" = "wants='integrationtest/ci/run'" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}

@test "built for /usr, the components look where Debian installs" {
  built_for configured prefix=/usr
  [ "$(directory_named_in tools/gettoken/bin/gettoken 's|^PATH="\([^:]*\):.*|\1|p')" = "/usr/lib/gettoken" ]
  [ "$(directory_named_in components/exchanger/exchanger 's|^plugins=.*:-\(.*\)}$|\1|p')" = "/usr/lib/gettoken/exchangers" ]
  [ "$(directory_named_in components/contract/contract.go 's|^[[:space:]]*return "\(.*/contracts\)"$|\1|p')" = "/usr/share/gettoken/contracts" ]
}

@test "a built tree leaves no directory undecided" {
  built_for configured "prefix=$there"
  run -1 --separate-stderr grep -rlE '@(libdir|datadir)@' "$built/tools" "$built/components"
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
}
