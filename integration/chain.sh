# shellcheck shell=sh

refusals=$(mktemp)

refused_with() {
  want=$1
  named=$2
  shift 2
  got=0
  "$@" > "$refusals" || got=$?
  [ "$got" -eq "$want" ] \
    || { echo "FAIL: $named exited $got, not $want"; exit 1; }
  [ ! -s "$refusals" ] \
    || { echo "FAIL: $named put $(cat "$refusals") on stdout while refusing"; exit 1; }
}

chain_runs() {
  capability=$1
  super_token=$2
  narrow_token=$3

  echo
  echo "# gettoken --list"
  list=$(gettoken --list)
  echo "$list"
  case "$list" in
    *"\"capability\":\"$capability\""*) ;;
    *) echo "FAIL: the entitlements do not name $capability"; exit 1 ;;
  esac

  echo
  echo "# gettoken $capability"
  out=$(gettoken "$capability")
  echo "$out"
  [ "$out" = "$narrow_token" ] \
    || { echo "FAIL: gettoken did not return the downgraded token alone"; exit 1; }
  [ "$out" != "$super_token" ] \
    || { echo "FAIL: gettoken handed over the super-token"; exit 1; }

  echo
  echo "# the tool runs on what gettoken handed over"
  INTEGRATIONTEST_TOKEN="$out" integration-test-tool

  echo
  echo "# the tool refuses the super-token, so the run above proves a downgrade"
  refused_with 1 integration-test-tool \
    env INTEGRATIONTEST_TOKEN="$super_token" integration-test-tool

  echo
  echo "# a capability no exchanger serves is refused, and hands over nothing"
  refused_with 1 gettoken gettoken nosuch/capability
}
