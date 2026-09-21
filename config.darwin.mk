PACKAGE_FORMATS = brew

INSTALL_COMMAND = $(subst ",,$(MAC_INSTALL_COMMAND))
BUILD_DEPS = jq bats-core shellcheck go kcov bash gnupg xmlstarlet
