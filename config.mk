BRANCH ?= $(shell bash -c 'source ./dynamic.sh >/dev/null 2>&1 && echo "$$BRANCH"')
SITE_URL ?= $(shell bash -c 'source ./dynamic.sh >/dev/null 2>&1 && echo "$$SITE_URL"')
PACKAGE_FORMATS ?= $(shell bash -c 'source ./dynamic.sh >/dev/null 2>&1 && echo "$$PACKAGE_FORMATS"')
INSTALL_COMMAND ?= $(shell bash -c 'source ./dynamic.sh >/dev/null 2>&1 && echo "$$INSTALL_COMMAND"')
BUILD_DEPS ?= $(shell bash -c 'source ./dynamic.sh >/dev/null 2>&1 && echo "$$BUILD_DEPS"')

-include config.local.mk
