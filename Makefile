export ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

-include build/config.mk

export PATH := build/bin:$(PATH_PREFIX)$(PATH)

.PHONY: all clean test diagrams config setup build contract package integration-test readme

all:              test
build:            package
test:             integration-test

diagrams:         build/diagrams.txt
config:           build/config.mk
setup:            build/setup.txt
package:          build/package.txt
contract:         build/bin/parse build/bin/format
integration-test: build/integration-test.checked

build/config.mk: dynamic.sh constants.env
	@mkdir -p $(@D)
	bash dynamic.sh > $@

build/sources:
	@mkdir -p $(@D)
	@find src scripts docs gates dynamic.sh agent_build.sh Makefile -type f -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

build/go-sources:
	@mkdir -p $(@D)
	@find src/components/contract -type f \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' \) \
	  -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

build/schema-sources:
	@mkdir -p $(@D)
	@find src/contracts -type f -name '*.schema.json' \
	  -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

build/tools.txt: build/config.mk
	@mkdir -p $(@D)
	bash -ec "$(INSTALL_COMMAND) $(BUILD_DEPS)"
	echo "$(BUILD_DEPS)" > $@

build/semgrep.txt: build/tools.txt
	bash -ec "$(SEMGREP_INSTALL_COMMAND)" > $@

build/versions.txt: build/tools.txt build/semgrep.txt
	bash scripts/versions.sh > $@

build/setup.txt: build/tools.txt build/semgrep.txt build/versions.txt
	bash -c "source dynamic.sh && ensure_bash5"
	cat $^ > $@

build/bin/parse build/bin/format: build/go-sources build/setup.txt
	bash src/components/contract/build.sh build/bin

include $(ROOT_DIR)/gates/gates.mk

build/package.txt: build/unit.txt build/lint.checked
	@mkdir -p $(@D)
	bash scripts/package.sh build/dist > $@
	cat $@

build/integration-test.checked: build/config.mk build/package.txt
	@mkdir -p $(@D)
	bash -ec "$$ADD_ARCHIVE"
	bash src/integration-test/test.sh > $@

build/diagrams.txt: build/sources README.md scripts/mermaid.sh
	@mkdir -p $(@D)
	scripts/mermaid.sh > $@
	cat $@

readme:
	bash gates/readme.sh . --write

clean:
	rm -rf build
