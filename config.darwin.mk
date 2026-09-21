PACKAGE_FORMATS = brew

MAC_INSTALL_COMMAND ?= brew install --no-ask
INSTALL_COMMAND ?= $(MAC_INSTALL_COMMAND)
BUILD_DEPS = jq bats-core shellcheck go kcov bash gnupg xmlstarlet
