PACKAGE_FORMATS = deb

DEBIAN_INSTALL_COMMAND ?= apt-get update && apt-get install -y --no-install-recommends
INSTALL_COMMAND ?= $(DEBIAN_INSTALL_COMMAND)
BUILD_DEPS = jq bats shellcheck golang-go kcov gnupg xmlstarlet dpkg-dev debhelper lintian build-essential golang-any apt-utils git curl ca-certificates perl
