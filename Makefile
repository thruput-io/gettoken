ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

export PATH := build/bin:$(PATH)

-include build/config.mk

export ARCHIVE_SIGNING_KEY ?= $(shell cat build/signing-key.asc 2>/dev/null)

.PHONY: all clean test diagrams stats config setup unit build contract signing-key lint lint-semgrep lint-shellcheck lint-go lint-make lint-schemas lint-permissions no-branching check-readme bash-unit-test bash-coverage go-unit-test go-coverage package package-brew publish integration-test readme build/unit.txt %.checked %.txt

all:              test
build:            publish
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
lint-permissions: build/check-permissions.txt
package:          build/package.txt
publish:          build/publish.txt
contract:         build/bin/parse build/bin/format
signing-key:      build/signing-key.asc
no-branching:     build/no-branching.checked
check-readme:     build/check-readme.txt
bash-unit-test:   build/bash-unit-test.checked
bash-coverage:    build/bash-coverage.checked
go-unit-test:     build/go-unit-test.checked
go-coverage:      build/go-coverage.checked
package-brew:     build/dist/brew/gettoken.rb
integration-test: build/integration-test.checked

%.checked: build/%.checked ;
%.txt:     build/%.txt ;


build/config.mk: dynamic.sh constants.env
	@mkdir -p $(@D)
	bash dynamic.sh > $@

build/sources:
	@mkdir -p $(@D)
	@find src scripts -type f -exec sha256sum {} + | sort -k 2 > $@.new
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

build/setup.txt: build/config.mk
	@mkdir -p $(@D)
	bash -ec "$(INSTALL_COMMAND) $(BUILD_DEPS)"
	bash scripts/fetch-semgrep-bash.sh build
	echo "$(BUILD_DEPS)" > $@

build/signing-key.asc: build/setup.txt
	bash scripts/generate-key.sh $@
	ARCHIVE_SIGNING_KEY="$$(cat $@)" bash scripts/signing-key.sh $@

build/bin/parse build/bin/format: build/go-sources build/setup.txt
	bash src/components/contract/build.sh build/bin

SHELL_FILES := $$(find src scripts -type f \( -name '*.sh' -o -name '*.postrm' -o -name 'entitlements' -o -name 'secret-*' -o -name 'token-*' -o -name 'gettoken' -o -name 'integration-test*' \) | grep -v -E '\.(json|1|manpages|install|bats)$$')

-include stats.mk

build/semgrep-report.json: build/sources build/setup.txt
	@mkdir -p $(@D)
	@if command -v semgrep-bash > /dev/null 2>&1; then semgrep-bash --json --json-output=$@ $$(find src scripts -type f \( -name '*.sh' -o -name '*.postrm' -o -name 'entitlements' -o -name 'secret-*' -o -name 'token-*' -o -name 'gettoken' -o -name 'integration-test*' \) | grep -v -E '\.(json|1|manpages|install|bats)$$'); elif [ -d "/Users/Shared/workspace/semgrep/bash/rules" ] && command -v semgrep > /dev/null 2>&1; then semgrep --json --config /Users/Shared/workspace/semgrep/bash/rules --output=$@ $$(find src scripts -type f \( -name '*.sh' -o -name '*.postrm' -o -name 'entitlements' -o -name 'secret-*' -o -name 'token-*' -o -name 'gettoken' -o -name 'integration-test*' \) | grep -v -E '\.(json|1|manpages|install|bats)$$'); else echo "semgrep not available" >&2; exit 1; fi

build/shellcheck-report.json: build/sources build/setup.txt
	@mkdir -p $(@D)
	shellcheck -s bash -x -f json $$(find src scripts -type f \( -name '*.sh' -o -name '*.postrm' -o -name 'entitlements' -o -name 'secret-*' -o -name 'token-*' -o -name 'gettoken' -o -name 'integration-test*' \) | grep -v -E '\.(json|1|manpages|install|bats)$$') > $@ || true

build/go-report.json: build/go-sources build/setup.txt
	@mkdir -p $(@D)
	go -C src/components/contract vet -json -mod=vendor ./... > $@

build/make-report.json: Makefile build/setup.txt
	@mkdir -p $(@D)
	checkmake -o json Makefile > $@

build/schema-report.json: build/schema-sources build/setup.txt
	@mkdir -p $(@D)
	check-jsonschema --check-metaschema --output-format=json src/contracts/*.schema.json > $@

build/check-permissions.txt: build/sources build/setup.txt
	@mkdir -p $(@D)
	umask 002 && bash scripts/check-permissions.sh src scripts > $@

build/check-readme.txt: build/sources README.md build/setup.txt
	@mkdir -p $(@D)
	bash scripts/readme.sh . --check > $@

build/report.tap: build/sources build/bin/parse build/bin/format build/setup.txt
	@mkdir -p $(@D)
	bats --recursive --timing --print-output-on-failure --formatter tap13 --report-formatter tap13 --output build src scripts

build/kcov/bats/coverage.json: build/sources build/bin/parse build/bin/format build/setup.txt
	@mkdir -p build/kcov
	kcov --clean --bash-parser=$$(command -v bash) --include-path=src,scripts --exclude-pattern=.bats,/bats-core/,/Cellar/bats-core/ build/kcov bats --recursive src scripts

build/go-unit-test.json: build/go-sources build/setup.txt
	@mkdir -p $(@D)
	go test -C src/components/contract -json -mod=vendor \
	  -coverprofile=$(ROOT_DIR)/build/go.coverprofile ./... > $@

build/go-coverage.txt: build/go-unit-test.json
	go -C src/components/contract tool cover \
	  -func=$(ROOT_DIR)/build/go.coverprofile > $@

.PHONY: build/shellcheck.checked build/make.checked build/schemas.checked build/go-lint.checked \
        build/semgrep.checked build/lint.checked build/no-branching.checked \
        build/bash-unit-test.checked build/bash-coverage.checked build/go-unit-test.checked \
        build/go-coverage.checked build/unit.txt

build/shellcheck.checked: build/shellcheck-report.json build/stats.txt
	errors=$$(jq '[.[] | select(.level=="error")] | length' $<); \
	warnings=$$(jq '[.[] | select(.level=="warning")] | length' $<); \
	echo "shellcheck: $$errors errors, $$warnings warnings (max 0/0, $(BASH_SOURCE_FILES) bash files scanned)"; \
	[ "$$errors" -le 0 ] && [ "$$warnings" -le 0 ] && [ "$(BASH_SOURCE_FILES)" -gt 0 ]

build/make.checked: build/make-report.json
	issues=$$([ -s $< ] && jq 'length' $< || echo 0); \
	echo "checkmake: $$issues issues (max 0)"; \
	[ "$$issues" -le 0 ]

build/schemas.checked: build/schema-report.json build/stats.txt
	status=$$(jq -r '.status' $<); errors=$$(jq '.errors | length' $<); \
	echo "schemas: $$errors errors, status=$$status (max 0, $(JSON_SCHEMAS) schemas checked)"; \
	[ "$$status" = "ok" ] && [ "$$errors" -le 0 ] && [ "$(JSON_SCHEMAS)" -gt 0 ]

build/go-lint.checked: build/go-report.json build/stats.txt
	issues=$$([ -s $< ] && jq -s '[.[][][][]] | length' $< || echo 0); \
	echo "go vet: $$issues issues (max 0, $(GO_SOURCE_FILES) go files scanned)"; \
	[ "$$issues" -le 0 ] && [ "$(GO_SOURCE_FILES)" -gt 0 ]

build/semgrep.checked: build/semgrep-report.json build/stats.txt
	findings=$$(jq '.results | length' $<); \
	echo "semgrep: $$findings findings (max 0, $(BASH_SOURCE_FILES) bash files scanned)"; \
	[ "$$findings" -le 0 ] && [ "$(BASH_SOURCE_FILES)" -gt 0 ]

build/lint.checked: build/shellcheck.checked build/make.checked build/schemas.checked build/go-lint.checked build/semgrep.checked build/check-permissions.txt
	@echo "All lint accept checks passed cleanly"

build/no-branching.checked: build/sources build/config.mk build/setup.txt
	bash scripts/check-branching.sh . 0

build/bash-unit-test.checked: build/report.tap build/stats.txt
	pass=$$(grep -c -- '^ok ' $<); fail=$$(grep -c -- '^not ok ' $<); \
	echo "bats: $$pass passed, $$fail failed (min 10, stat $(BATS_TESTS))"; \
	[ "$$fail" -eq 0 ] && [ "$$pass" -gt 10 ] && [ "$$(( $$pass + $$fail ))" -eq "$(BATS_TESTS)" ]

build/bash-coverage.checked: build/kcov/bats/coverage.json build/stats.txt
	percent=$$(jq -r '.percent_covered' $<); \
	files=$$(jq -r '.files | length' $<); \
	echo "bash-coverage: $$percent% covered, floor 22%, $$files files (stat $(BASH_SOURCE_FILES))"; \
	[ "$${percent%.*}" -ge 22 ] && [ "$$files" -eq "$(BASH_SOURCE_FILES)" ]

build/go-coverage.checked: build/go-coverage.txt build/stats.txt
	percent=$$(grep '^total:' $< | grep -oE '[0-9.]+%$$' | tr -d '%'); \
	files=$$(grep -v '^total:' $< | cut -d: -f1 | sort -u | wc -l); \
	echo "go-coverage: $$percent% covered, floor 80%, $$files files (stat $(GO_SOURCE_FILES))"; \
	[ "$${percent%.*}" -ge 80 ] && [ "$$files" -eq "$(GO_SOURCE_FILES)" ]

build/go-unit-test.checked: build/go-unit-test.json build/stats.txt
	pass=$$(grep -c -- '--- PASS:' $<); fail=$$(grep -c -- '--- FAIL:' $<); ran=$$(grep -c -- '=== RUN' $<); \
	echo "go test: $$pass passed, $$fail failed, $$ran run (min 10, stat $(GO_TESTS))"; \
	[ "$$fail" -eq 0 ] && [ "$$pass" -gt 10 ] && [ "$$ran" -eq "$$(($$pass + $$fail))" ] && [ "$$ran" -eq "$(GO_TESTS)" ]

build/unit.txt: build/check-readme.txt build/no-branching.checked build/check-permissions.txt \
                build/bash-unit-test.checked build/bash-coverage.checked \
                build/go-unit-test.checked build/go-coverage.checked
	@echo "unit: all checks passed"

build/dist/deb/packages: build/unit.txt build/lint.checked src/debian src/contracts
	bash scripts/package-deb.sh build/dist/deb
	@touch $@

build/dist/brew/gettoken.rb: build/unit.txt build/lint.checked src/debian/changelog
	bash scripts/package-brew.sh build/dist/brew

build/archive.txt: build/dist/deb/packages build/signing-key.asc
	bash scripts/archive.sh build/dist/deb build/site/apt "$(BRANCH)" build/signing-key.asc > $@
	bash scripts/sources.sh build/site/apt "$(BRANCH)" "$(SITE_URL)/apt" >> $@

build/package.txt: build/archive.txt build/dist/brew/gettoken.rb
	cat $^ > $@
	cat $@

build/publish.txt: build/package.txt
	bash scripts/publish.sh build/site/apt "$(BRANCH)" "$(SITE_URL)" > $@
	cat $@

build/integration-test.checked: build/publish.txt build/config.mk
	@mkdir -p $(@D)
	INSTALL_COMMAND="$(INSTALL_COMMAND)" SITE_URL="$(SITE_URL)" BRANCH="$(BRANCH)" bash src/integration-test/test.sh > $@

build/diagrams.txt: build/sources README.md scripts/mermaid.sh
	@mkdir -p $(@D)
	scripts/mermaid.sh > $@
	cat $@

readme:
	scripts/readme.sh . --write

clean:
	rm -rf build
