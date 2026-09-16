# 27. Platform by makefile

## Decision

Makefile shall produce a brew package (formula only, built from source, no bottle) and debian package. The only difference between executioners of makefile is apt or brew, the setup target will install the build tools needed using the INSTALL_COMMAND BUILD_DEPS.

brew package and debian package are hard-coded out-comes of the Makefile, both should be produced no matter the builders platform.

Make test will execute integrationstest/test.sh test.sh. test.sh will have two parameters INSTALL_COMMAND and UNPRIVILEGED_USER. It will pull package by invoking provided INSTALL_COMMAND {get token-package} it will use sudo to UNPRIVILEGED_USER to do unprivileged actions, It will assume user running the script is correct PRIVILIGED_USER.

Config.sh will provide configuration of the build, in this moment something like this:
Variables can only be declared in config.sh

config.sh will export: configuration should work on github build agent
export PUBLISH_BREW_COMMAND=xxx<something that works in build pipeline>
export PUBLISH_APT_COMANND=xxx<something that works in build pipeline>
export INSTALL_COMMAND=sudo apt-get install -y --no-install-recommends
export BUILD_DEPS=jq bats-core shellcheck go kcov bash gnupg
export UNPRIVILEGED_USER=nonroot

A variant tha can be used by developer on a mac.
config.local.sh=brew install --no-ask
export PUBLISH_BREW_COMMAND=xxx<something that works locally>
export PUBLISH_APT_COMANND=xxx<something that works locally>
export INSTALL_COMMAND=sudo apt-get install -y --no-install-recommends
export BUILD_DEPS=jq bats-core shellcheck go kcov bash gnupg
export UNPRIVILEGED_USER=user

Build Chain
Makefile will produce both package types brew and apt. Makefile has no notion what platform it is executing on setup will invoke:
"make setup" will only do
INSTALL_COMMAND BUILD_DEPS

publish will publish respective package by invoking
PUBLISH_BREW_COMMAND <package>
PUBLISH_APT_COMANND <package>

make test will execute integrationstest/test.sh test.sh. test.sh will have two parameters INSTALL_COMMAND and UNPRIVILEGED_USER. It will pull package by invoking provided INSTALL_COMMAND {get token-package} it will use sudo to UNPRIVILEGED_USER to do unprivileged actions, It will assume user running the script is correct PRIVILIGED_USER.

On build pipeline a mtraix with all three target plaforms will be configured
each will just invoke test.sh with parameters INSTALL_COMMAND and UNPRIVILEGED_USER those variables will be set in pipeline yaml

