# shellcheck shell=bash

if [ -f ./config.local.sh ]; then
  # shellcheck source=config.local.sh
  . ./config.local.sh
fi

export PACKAGE_FORMATS="${PACKAGE_FORMATS:-deb brew}"

export INSTALL_COMMAND="${INSTALL_COMMAND:-sudo apt-get install -y --no-install-recommends}"
export BUILD_DEPS="${BUILD_DEPS:-jq bats shellcheck golang-go kcov gnupg dpkg-dev debhelper lintian build-essential golang-any apt-utils}"
export UNPRIVILEGED_USER="${UNPRIVILEGED_USER:-nonroot}"
export PUBLISH_DEB_COMMAND="${PUBLISH_DEB_COMMAND:-./scripts/publish-deb.sh}"
export PUBLISH_BREW_COMMAND="${PUBLISH_BREW_COMMAND:-./scripts/publish-brew.sh}"

