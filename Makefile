export ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

-include $(ROOT_DIR)/build/config.mk

export PATH := $(ROOT_DIR)/build/bin:$(PATH_PREFIX)$(PATH)

.PHONY: all clean test diagrams stats config setup unit build contract lint lint-semgrep lint-shellcheck lint-go lint-make lint-schemas lint-permissions no-branching check-readme bash-unit-test bash-coverage go-unit-test go-coverage package integration-test readme $(ROOT_DIR)/build/unit.txt

all:              test
build:            package
test:             integration-test

diagrams:         $(ROOT_DIR)/build/diagrams.txt
stats:            $(ROOT_DIR)/build/stats.txt
config:           $(ROOT_DIR)/build/config.mk
setup:            $(ROOT_DIR)/build/setup.txt
unit:             $(ROOT_DIR)/build/unit.txt
lint:             $(ROOT_DIR)/build/lint.checked
lint-semgrep:     $(ROOT_DIR)/build/semgrep.checked
lint-shellcheck:  $(ROOT_DIR)/build/shellcheck.checked
lint-go:          $(ROOT_DIR)/build/go-lint.checked
lint-make:        $(ROOT_DIR)/build/make.checked
lint-schemas:     $(ROOT_DIR)/build/schemas.checked
lint-permissions: $(ROOT_DIR)/build/check-permissions.txt
package:          $(ROOT_DIR)/build/package.txt
contract:         $(ROOT_DIR)/build/bin/parse $(ROOT_DIR)/build/bin/format
no-branching:     $(ROOT_DIR)/build/no-branching.checked
check-readme:     $(ROOT_DIR)/build/check-readme.txt
bash-unit-test:   $(ROOT_DIR)/build/bash-unit-test.checked
bash-coverage:    $(ROOT_DIR)/build/bash-coverage.checked
go-unit-test:     $(ROOT_DIR)/build/go-unit-test.checked
go-coverage:      $(ROOT_DIR)/build/go-coverage.checked
integration-test: $(ROOT_DIR)/build/integration-test.checked

$(ROOT_DIR)/build/config.mk: $(ROOT_DIR)/dynamic.sh $(ROOT_DIR)/constants.env
	@mkdir -p $(@D)
	bash $(ROOT_DIR)/dynamic.sh > $@

$(ROOT_DIR)/build/sources:
	@mkdir -p $(@D)
	@find $(ROOT_DIR)/src $(ROOT_DIR)/scripts -type f -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

$(ROOT_DIR)/build/go-sources:
	@mkdir -p $(@D)
	@find $(ROOT_DIR)/src/components/contract -type f \( -name '*.go' -o -name 'go.mod' -o -name 'go.sum' \) \
	  -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

$(ROOT_DIR)/build/schema-sources:
	@mkdir -p $(@D)
	@find $(ROOT_DIR)/src/contracts -type f -name '*.schema.json' \
	  -exec sha256sum {} + | sort -k 2 > $@.new
	@cmp -s $@.new $@ && rm $@.new || mv $@.new $@

$(ROOT_DIR)/build/tools.txt: $(ROOT_DIR)/build/config.mk
	@mkdir -p $(@D)
	bash -ec "$(INSTALL_COMMAND) $(BUILD_DEPS)"
	echo "$(BUILD_DEPS)" > $@

$(ROOT_DIR)/build/semgrep.txt: $(ROOT_DIR)/build/tools.txt
	bash -ec "$(SEMGREP_INSTALL_COMMAND)"
	bash $(ROOT_DIR)/scripts/fetch-semgrep-bash.sh $(ROOT_DIR)/build > $@

$(ROOT_DIR)/build/versions.txt: $(ROOT_DIR)/build/tools.txt $(ROOT_DIR)/build/semgrep.txt
	bash $(ROOT_DIR)/scripts/versions.sh > $@

$(ROOT_DIR)/build/setup.txt: $(ROOT_DIR)/build/tools.txt $(ROOT_DIR)/build/semgrep.txt $(ROOT_DIR)/build/versions.txt
	bash -c "source $(ROOT_DIR)/dynamic.sh && ensure_bash5"
	cat $^ > $@

$(ROOT_DIR)/build/bin/parse $(ROOT_DIR)/build/bin/format: $(ROOT_DIR)/build/go-sources $(ROOT_DIR)/build/setup.txt
	bash $(ROOT_DIR)/src/components/contract/build.sh $(ROOT_DIR)/build/bin

include $(ROOT_DIR)/stats.mk

$(ROOT_DIR)/build/semgrep-report.json: $(ROOT_DIR)/build/sources $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	bash $(ROOT_DIR)/scripts/reporters/semgrep.sh $@

$(ROOT_DIR)/build/shellcheck-report.json: $(ROOT_DIR)/build/sources $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	bash $(ROOT_DIR)/scripts/reporters/shellcheck.sh $@

$(ROOT_DIR)/build/go-report.json: $(ROOT_DIR)/build/go-sources $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	go -C $(ROOT_DIR)/src/components/contract vet -json -mod=vendor ./... > $@

$(ROOT_DIR)/build/make-report.json: $(ROOT_DIR)/Makefile $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	checkmake -o json $(ROOT_DIR)/Makefile > $@

$(ROOT_DIR)/build/schema-report.json: $(ROOT_DIR)/build/schema-sources $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	check-jsonschema --check-metaschema --output-format=json $(ROOT_DIR)/src/contracts/*.schema.json > $@

$(ROOT_DIR)/build/check-permissions.txt: $(ROOT_DIR)/build/sources $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	umask 002 && bash $(ROOT_DIR)/scripts/check-permissions.sh $(ROOT_DIR)/src $(ROOT_DIR)/scripts > $@

$(ROOT_DIR)/build/check-readme.txt: $(ROOT_DIR)/build/sources $(ROOT_DIR)/README.md $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	bash $(ROOT_DIR)/scripts/readme.sh $(ROOT_DIR) --check > $@

$(ROOT_DIR)/build/report.tap: $(ROOT_DIR)/build/sources $(ROOT_DIR)/build/bin/parse $(ROOT_DIR)/build/bin/format $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	bats --recursive --timing --print-output-on-failure --formatter tap13 --report-formatter tap13 --output $(ROOT_DIR)/build $(ROOT_DIR)/src $(ROOT_DIR)/scripts

$(ROOT_DIR)/build/kcov/bats/coverage.json: $(ROOT_DIR)/build/sources $(ROOT_DIR)/build/bin/parse $(ROOT_DIR)/build/bin/format $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(ROOT_DIR)/build/kcov
	kcov --clean --bash-parser=$$(command -v bash) --bash-parse-files-in-dir=$(ROOT_DIR)/src --include-path=$(ROOT_DIR)/src --exclude-pattern=.bats,/bats-core/,/Cellar/bats-core/ $(ROOT_DIR)/build/kcov bats --recursive $(ROOT_DIR)/src $(ROOT_DIR)/scripts

$(ROOT_DIR)/build/go-unit-test.json: $(ROOT_DIR)/build/go-sources $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	go test -C $(ROOT_DIR)/src/components/contract -json -mod=vendor \
	  -coverprofile=$(ROOT_DIR)/build/go.coverprofile ./... > $@

$(ROOT_DIR)/build/go-coverage.txt: $(ROOT_DIR)/build/go-unit-test.json
	go -C $(ROOT_DIR)/src/components/contract tool cover \
	  -func=$(ROOT_DIR)/build/go.coverprofile > $@

.PHONY: $(ROOT_DIR)/build/shellcheck.checked $(ROOT_DIR)/build/make.checked $(ROOT_DIR)/build/schemas.checked $(ROOT_DIR)/build/go-lint.checked \
        $(ROOT_DIR)/build/semgrep.checked $(ROOT_DIR)/build/lint.checked $(ROOT_DIR)/build/no-branching.checked \
        $(ROOT_DIR)/build/bash-unit-test.checked $(ROOT_DIR)/build/bash-coverage.checked $(ROOT_DIR)/build/go-unit-test.checked \
        $(ROOT_DIR)/build/go-coverage.checked $(ROOT_DIR)/build/unit.txt

$(ROOT_DIR)/build/shellcheck.checked: $(ROOT_DIR)/build/shellcheck-report.json $(ROOT_DIR)/build/stats.txt
	set -euo pipefail; errors=$$(jq '[.[] | select(.level=="error")] | length' $<); \
	warnings=$$(jq '[.[] | select(.level=="warning")] | length' $<); \
	echo "shellcheck: $$errors errors, $$warnings warnings (max 0/0, $(BASH_SOURCE_FILES) bash files scanned)"; \
	[ "$$errors" -le 0 ] && [ "$$warnings" -le 0 ] && [ "$(BASH_SOURCE_FILES)" -gt 20 ]

$(ROOT_DIR)/build/make.checked: $(ROOT_DIR)/build/make-report.json
	set -euo pipefail; issues=$$(jq -s 'add | length' $<); \
	echo "checkmake: $$issues issues (max 0)"; \
	[ "$$issues" -le 0 ]

$(ROOT_DIR)/build/schemas.checked: $(ROOT_DIR)/build/schema-report.json $(ROOT_DIR)/build/stats.txt
	set -euo pipefail; status=$$(jq -r '.status' $<); errors=$$(jq '.errors | length' $<); \
	echo "schemas: $$errors errors, status=$$status (max 0, $(JSON_SCHEMAS) schemas checked)"; \
	[ "$$status" = "ok" ] && [ "$$errors" -le 0 ] && [ "$(JSON_SCHEMAS)" -gt 0 ]

$(ROOT_DIR)/build/go-lint.checked: $(ROOT_DIR)/build/go-report.json $(ROOT_DIR)/build/stats.txt
	set -euo pipefail; issues=$$(jq -s '[.[][][][]] | length' $<); \
	echo "go vet: $$issues issues (max 0, $(GO_SOURCE_FILES) go files scanned)"; \
	[ "$$issues" -le 0 ] && [ "$(GO_SOURCE_FILES)" -gt 0 ]

$(ROOT_DIR)/build/semgrep.checked: $(ROOT_DIR)/build/semgrep-report.json $(ROOT_DIR)/build/stats.txt
	set -euo pipefail; findings=$$(jq '.results | length' $<); unparsed=$$(jq '.errors | length' $<); \
	echo "semgrep: $$findings findings, $$unparsed files not fully parsed (max 0/0, $(BASH_SOURCE_FILES) bash files scanned)"; \
	[ "$$findings" -le 0 ] && [ "$$unparsed" -le 0 ] && [ "$(BASH_SOURCE_FILES)" -gt 20 ]

$(ROOT_DIR)/build/lint.checked: $(ROOT_DIR)/build/shellcheck.checked $(ROOT_DIR)/build/make.checked $(ROOT_DIR)/build/schemas.checked $(ROOT_DIR)/build/go-lint.checked $(ROOT_DIR)/build/semgrep.checked
	@echo "All lint accept checks passed cleanly"

$(ROOT_DIR)/build/branching-report.txt: $(ROOT_DIR)/build/sources $(ROOT_DIR)/build/setup.txt
	@mkdir -p $(@D)
	bash $(ROOT_DIR)/scripts/branching.sh $(ROOT_DIR) > $@

$(ROOT_DIR)/build/no-branching.checked: $(ROOT_DIR)/build/branching-report.txt $(ROOT_DIR)/build/stats.txt
	set -euo pipefail; sites=$$(wc -l < $< | tr -d ' '); \
	echo "no-branching: $$sites sites branch or default in tests (max 0, $(BATS_TEST_FILES) test files scanned)"; \
	[ "$$sites" -le 0 ] && [ "$(BATS_TEST_FILES)" -gt 0 ]

$(ROOT_DIR)/build/bash-unit-test.checked: $(ROOT_DIR)/build/report.tap $(ROOT_DIR)/build/stats.txt
	set -uo pipefail; pass=$$(grep -c -- '^ok ' $<); fail=$$(grep -c -- '^not ok ' $<); \
	echo "bats: $$pass passed, $$fail failed (min 10, stat $(BATS_TESTS))"; \
	[ "$$fail" -eq 0 ] && [ "$$pass" -ge 10 ] && [ "$$(( $$pass + $$fail ))" -eq "$(BATS_TESTS)" ]

$(ROOT_DIR)/build/bash-coverage.checked: $(ROOT_DIR)/build/kcov/bats/coverage.json $(ROOT_DIR)/build/stats.txt
	set -euo pipefail; percent=$$(jq -r '.percent_covered' $<); \
	files=$$(jq -r '.files | length' $<); \
	echo "bash-coverage: $$percent% covered, floor 22%, $$files files (stat $(BASH_SOURCE_FILES))"; \
	[ "$${percent%.*}" -ge 22 ] && [ "$$files" -gt 0 ]

$(ROOT_DIR)/build/go-coverage.checked: $(ROOT_DIR)/build/go-coverage.txt $(ROOT_DIR)/build/stats.txt
	set -euo pipefail; percent=$$(grep '^total:' $< | grep -oE '[0-9.]+%$$' | tr -d '%'); \
	files=$$(grep -v '^total:' $< | cut -d: -f1 | sort -u | wc -l); \
	echo "go-coverage: $$percent% covered, floor 44%, $$files files (stat $(GO_SOURCE_FILES))"; \
	[ "$${percent%.*}" -ge 44 ] && [ "$$files" -gt 0 ]

$(ROOT_DIR)/build/go-unit-test.checked: $(ROOT_DIR)/build/go-unit-test.json $(ROOT_DIR)/build/stats.txt
	set -uo pipefail; pass=$$(grep -c -- '--- PASS:' $<); fail=$$(grep -c -- '--- FAIL:' $<); ran=$$(grep -c -- '=== RUN' $<); \
	echo "go test: $$pass passed, $$fail failed, $$ran run (min 10, stat $(GO_TESTS))"; \
	[ "$$fail" -eq 0 ] && [ "$$pass" -ge 10 ] && [ "$$ran" -eq "$$(($$pass + $$fail))" ] && [ "$$ran" -eq "$(GO_TESTS)" ]

$(ROOT_DIR)/build/unit.txt: $(ROOT_DIR)/build/check-readme.txt $(ROOT_DIR)/build/no-branching.checked $(ROOT_DIR)/build/check-permissions.txt \
                $(ROOT_DIR)/build/bash-unit-test.checked $(ROOT_DIR)/build/bash-coverage.checked \
                $(ROOT_DIR)/build/go-unit-test.checked $(ROOT_DIR)/build/go-coverage.checked
	@echo "unit: all checks passed"

$(ROOT_DIR)/build/package.txt: $(ROOT_DIR)/build/unit.txt $(ROOT_DIR)/build/lint.checked
	@mkdir -p $(@D)
	bash $(ROOT_DIR)/scripts/package.sh $(ROOT_DIR)/build/dist > $@
	cat $@

$(ROOT_DIR)/build/integration-test.checked: $(ROOT_DIR)/build/config.mk $(ROOT_DIR)/build/package.txt
	@mkdir -p $(@D)
	bash -ec "$$ADD_ARCHIVE"
	bash $(ROOT_DIR)/src/integration-test/test.sh > $@

$(ROOT_DIR)/build/diagrams.txt: $(ROOT_DIR)/build/sources $(ROOT_DIR)/README.md $(ROOT_DIR)/scripts/mermaid.sh
	@mkdir -p $(@D)
	$(ROOT_DIR)/scripts/mermaid.sh > $@
	cat $@

readme:
	$(ROOT_DIR)/scripts/readme.sh $(ROOT_DIR) --write

clean:
	rm -rf $(ROOT_DIR)/build
