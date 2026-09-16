# shellcheck shell=bash

export PACKAGE_FORMATS="${PACKAGE_FORMATS:-deb brew}"

export INSTALL_COMMAND="${INSTALL_COMMAND:-brew install --no-ask}"
export BUILD_DEPS="${BUILD_DEPS:-jq bats-core shellcheck go kcov bash gnupg dpkg}"
export UNPRIVILEGED_USER="${UNPRIVILEGED_USER:-$(id -un)}"
export PUBLISH_DEB_COMMAND="${PUBLISH_DEB_COMMAND:-./scripts/publish-deb.sh}"
export PUBLISH_BREW_COMMAND="${PUBLISH_BREW_COMMAND:-./scripts/publish-brew.sh}"

