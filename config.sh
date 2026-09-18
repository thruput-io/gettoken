export PACKAGE_FORMATS = deb

export INSTALL_COMMAND = sudo apt-get install -y --no-install-recommends
export BUILD_DEPS = jq bats shellcheck golang-go kcov gnupg xmlstarlet dpkg-dev debhelper lintian build-essential golang-any apt-utils
export SITE_URL = https://thruput.se/gettoken
