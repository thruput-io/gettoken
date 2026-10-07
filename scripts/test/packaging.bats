bats_require_minimum_version 1.5.0

setup() {
  root=$ROOT_DIR
  export root
}

install_lists() {
  find "$root/src" -type f -name '*.install' | sort
}

installed_into() {
  local lists
  mapfile -t lists < <(install_lists)
  awk -v want="$1" '$2 == want { n = split($1, p, "/"); print p[n] }' "${lists[@]}" | sort
}

destinations() {
  local lists
  mapfile -t lists < <(install_lists)
  awk '{ print $2 }' "${lists[@]}" | sort -u
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
  grep -q 'usr/lib/gettoken/exchangers' "$root/src/tools/integration-test-tool/integration-test-tool-exchanger.install"
}
