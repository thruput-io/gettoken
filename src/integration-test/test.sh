#!/usr/bin/env bash
set -euo pipefail

dist=${1:?test.sh: name the directory the packages were delivered into}
install_command=${INSTALL_COMMAND:?test.sh: name the INSTALL_COMMAND}
tap=${BREW_TAP:?test.sh: name the BREW_TAP the formulae depend on each other through}

dist=$(CDPATH='' cd "$dist" && pwd)

for fmt in ${PACKAGE_FORMATS:?test.sh: name the PACKAGE_FORMATS to install}; do
  case "$fmt" in
    deb)
      bash -ec "$install_command $dist/deb/*.deb"
      privileged=/usr/lib/gettoken
      ;;
    brew)
      tarball=$(find "$dist/brew" -name '*.tar.gz')
      brew tap-new --no-git "$tap"
      brew trust "$tap"
      formulae=$(brew --repository "$tap")/Formula
      mkdir -p "$formulae"
      for formula in "$dist"/brew/*.rb; do
        sed "s|^  url .*|  url \"file://$tarball\"|" "$formula" > "$formulae/$(basename "$formula")"
      done
      bash -ec "$install_command $tap/integration-test-tool $tap/gettoken"
      privileged=$(brew --prefix)/lib/gettoken
      ;;
    *)
      echo "test.sh: no installation for format '$fmt'" >&2
      exit 1
      ;;
  esac
done

carried=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')

PATH=$privileged:$PATH secret-put > /dev/null <<SUPERTOKEN
{"key":"host-privileged/integrationtest","value":"super-$carried"}
SUPERTOKEN

INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run)
export INTEGRATIONTEST_TOKEN
ran_on=$(integration-test-tool)

test "$ran_on" = "$carried"

for fmt in $PACKAGE_FORMATS; do
  case "$fmt" in
    deb)
      apt-get purge -y gettoken-secret-manager
      test ! -e /var/lib/gettoken
      ;;
    brew)
      read -ra installed <<< "$(brew list --formula --full-name | grep "^$tap/" | tr '\n' ' ')"
      brew uninstall --formula "${installed[@]}"
      ;;
    *)
      echo "test.sh: no removal for format '$fmt'" >&2
      exit 1
      ;;
  esac
done
