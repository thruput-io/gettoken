bats_require_minimum_version 1.5.0

setup() {
  root=$(CDPATH='' cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export root
}

installed_into() {
  awk -v want="$1" '$2 == want { n = split($1, p, "/"); print p[n] }' "$root"/debian/*.install | sort
}

destinations() {
  awk '{ print $2 }' "$root"/debian/*.install | sort -u
}

destinations_reachable_without_gettoken_on_path() {
  destinations | grep -vxE 'usr/bin|usr/lib/gettoken(/.*)?|usr/share/gettoken(/.*)?'
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
  grep -q 'usr/lib/gettoken/exchangers' "$root/debian/integration-test-tool-exchanger.install"
}
