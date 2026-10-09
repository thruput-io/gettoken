export ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

-include build/config.mk

export PATH := build/bin:$(PATH_PREFIX)$(PATH)

.PHONY: all clean test diagrams stats config setup unit build contract lint lint-semgrep lint-shellcheck lint-go lint-make lint-schemas lint-json lint-env lint-workflows lint-permissions no-branching check-readme bash-unit-test bash-coverage go-unit-test go-coverage package integration-test readme build/unit.txt

all:              test
build:            package
test:             integration-test

diagrams:         build/diagrams.txt
stats:            build/stats.txt
config:           build/config.mk
setup:            build/setup.txt
unit:             build/unit.txt
lint:             build/lint.checked
lint-semgrep:     build/semgrep.checked
lint-shellcheck:  build/shellcheck.checked
lint-go:          build/go-lint.checked
lint-make:        build/make.checked
lint-schemas:     build/schemas.checked
lint-json:        build/json.checked
lint-env:         build/env.checked
lint-workflows:   build/workflows.checked build/actions.checked
lint-permissions: build/check-permissions.txt
package:          build/package.txt
contract:         build/bin/parse build/bin/format
no-branching:     build/no-branching.checked
check-readme:     build/check-readme.txt
bash-unit-test:   build/bash-unit-test.checked
bash-coverage:    build/bash-coverage.checked
go-unit-test:     build/go-unit-test.checked
go-coverage:      build/go-coverage.checked
integration-test: build/integration-test.checked

build/config.mk: dynamic.sh constants.env
	@mkdir -p $(@D)
	bash dynamic.sh > $@

build/tools.txt: build/config.mk
	@mkdir -p $(@D)
	bash -ec "$(INSTALL_COMMAND) $(BUILD_DEPS)"
	echo "$(BUILD_DEPS)" > $@

build/semgrep.txt: build/tools.txt
	bash -ec "$(SEMGREP_INSTALL_COMMAND)"
	bash scripts/protected/fetch-semgrep-bash.sh build > $@

build/versions.txt: build/tools.txt build/semgrep.txt
	bash scripts/protected/versions.sh > $@

build/setup.txt: build/tools.txt build/semgrep.txt build/versions.txt
	bash -c "source dynamic.sh && ensure_bash5"
	cat $^ > $@

build/bin/parse build/bin/format: build/sources build/setup.txt
	bash src/components/contract/build.sh build/bin

PROTECTED := scripts/protected
REPORT    := bash $(PROTECTED)/reporters
CHECK     := bash $(PROTECTED)/checkers

include $(ROOT_DIR)/$(PROTECTED)/stats.mk

build/shellcheck-report.json: build/sources build/setup.txt
	$(REPORT)/shellcheck.sh $@

build/semgrep-report.json: build/sources build/setup.txt
	$(REPORT)/semgrep.sh $@

build/make-report.json: build/sources build/setup.txt
	$(REPORT)/checkmake.sh $@ $(PROTECTED)/checkmake.ini

build/make-fragments-report.json: build/sources build/setup.txt
	$(REPORT)/checkmake-fragments.sh $@ $(PROTECTED)/checkmake-fragments.ini

build/schema-report.json: build/sources build/setup.txt
	$(REPORT)/jsonschema.sh $@ --check-metaschema '*.schema.json'

build/workflows-report.json: build/sources build/setup.txt
	$(REPORT)/jsonschema.sh $@ --builtin-schema=vendor.github-workflows '.github/workflows/*.yml'

build/actions-report.json: build/sources build/setup.txt
	$(REPORT)/jsonschema.sh $@ --builtin-schema=vendor.github-actions '.github/actions/*/action.yml'

build/json-report.tsv: build/sources build/setup.txt
	$(REPORT)/json.sh $@

build/env-report.tsv: build/sources build/setup.txt
	$(REPORT)/env.sh $@

build/go-report.json: build/sources build/setup.txt
	$(REPORT)/go-vet.sh $@ src/components/contract

build/branching-report.txt: build/sources build/setup.txt
	$(REPORT)/branching.sh $@

build/check-permissions.txt: build/sources build/setup.txt
	umask 002 && $(CHECK)/permissions.sh > $@

build/check-readme.txt: build/sources build/setup.txt
	$(CHECK)/readme.sh . --check > $@

build/report.tap: build/sources build/bin/parse build/bin/format build/setup.txt
	$(REPORT)/bats.sh $@ $(ROOT_DIR)/build

build/kcov/bats/coverage.json: build/sources build/bin/parse build/bin/format build/setup.txt
	$(REPORT)/kcov.sh build/kcov-report.txt build/kcov

build/go-unit-test.json: build/sources build/setup.txt
	$(REPORT)/go-test.sh $@ src/components/contract $(ROOT_DIR)/build/go.coverprofile

build/go-coverage.txt: build/go-unit-test.json
	$(REPORT)/go-coverage.sh $@ src/components/contract $(ROOT_DIR)/build/go.coverprofile

.PHONY: build/shellcheck.checked build/semgrep.checked build/make.checked
.PHONY: build/make-fragments.checked build/schemas.checked build/workflows.checked build/actions.checked
.PHONY: build/json.checked build/env.checked build/go-lint.checked build/lint.checked build/no-branching.checked
.PHONY: build/bash-unit-test.checked build/bash-coverage.checked build/go-unit-test.checked
.PHONY: build/go-coverage.checked build/unit.txt

build/shellcheck.checked: build/shellcheck-report.json build/stats.txt
	$(CHECK)/shellcheck.sh $^

build/semgrep.checked: build/semgrep-report.json build/stats.txt
	$(CHECK)/semgrep.sh $^

build/make.checked: build/make-report.json build/stats.txt
	$(CHECK)/make.sh $^ 'make files' MAKE_FILES_MIN

build/make-fragments.checked: build/make-fragments-report.json build/stats.txt
	$(CHECK)/make.sh $^ 'make fragments' MAKE_FRAGMENTS_MIN

build/schemas.checked: build/schema-report.json build/stats.txt
	$(CHECK)/jsonschema.sh $^ 'json schemas' JSON_SCHEMAS_MIN

build/workflows.checked: build/workflows-report.json build/stats.txt
	$(CHECK)/jsonschema.sh $^ 'workflow files' WORKFLOW_FILES_MIN

build/actions.checked: build/actions-report.json build/stats.txt
	$(CHECK)/jsonschema.sh $^ 'action files' ACTION_FILES_MIN

build/json.checked: build/json-report.tsv build/stats.txt
	$(CHECK)/json.sh $^

build/env.checked: build/env-report.tsv build/stats.txt
	$(CHECK)/env.sh $^

build/go-lint.checked: build/go-report.json build/stats.txt
	$(CHECK)/go-lint.sh $^

build/lint.checked: build/shellcheck.checked build/semgrep.checked \
                    build/make.checked build/make-fragments.checked build/schemas.checked \
                    build/workflows.checked build/actions.checked build/json.checked build/env.checked \
                    build/go-lint.checked
	@echo "lint: all checks passed"

build/no-branching.checked: build/branching-report.txt build/stats.txt
	$(CHECK)/no-branching.sh $^

build/bash-unit-test.checked: build/report.tap build/stats.txt
	$(CHECK)/bash-unit-test.sh $^

build/bash-coverage.checked: build/kcov/bats/coverage.json build/stats.txt
	$(CHECK)/bash-coverage.sh $^

build/go-unit-test.checked: build/go-unit-test.json build/stats.txt
	$(CHECK)/go-unit-test.sh $^

build/go-coverage.checked: build/go-coverage.txt build/stats.txt
	$(CHECK)/go-coverage.sh $^

build/unit.txt: build/check-readme.txt build/no-branching.checked build/check-permissions.txt \
                build/bash-unit-test.checked build/bash-coverage.checked \
                build/go-unit-test.checked build/go-coverage.checked
	@echo "unit: all checks passed"

build/package.txt: build/unit.txt build/lint.checked
	@mkdir -p $(@D)
	bash scripts/package.sh build/dist > $@
	cat $@

build/integration-test.checked: build/config.mk build/package.txt
	@mkdir -p $(@D)
	bash scripts/add-archive.sh
	bash src/integration-test/test.sh > $@

build/diagrams.txt: build/sources
	@mkdir -p $(@D)
	scripts/mermaid.sh > $@
	cat $@

readme:
	$(PROTECTED)/checkers/readme.sh . --write

clean:
	rm -rf build
