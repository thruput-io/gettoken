# shellcheck shell=bash

export PACKAGE_FORMATS="deb"

export INSTALL_COMMAND="sudo apt-get install -y --no-install-recommends"
export BUILD_DEPS="jq bats shellcheck golang-go kcov gnupg xmlstarlet dpkg-dev debhelper lintian build-essential golang-any apt-utils"
export PUBLISH_DEB_COMMAND="scripts/publish-to-pages.sh gh-pages docs/deb"
export PUBLISH_BREW_COMMAND="scripts/publish-to-pages.sh gh-pages docs/brew"
