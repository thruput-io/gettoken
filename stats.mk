BASH_SOURCE_FILES := $(strip $(shell cd $(ROOT_DIR) && { git ls-files --cached --others --exclude-standard -- '*.sh' '*.bash' '*.bats'; git ls-files --cached --others --exclude-standard | tr '\n' '\0' | xargs -0 awk 'FNR == 1 && $$0 ~ /^\#!.*(sh|bats)$$/ { print FILENAME } { nextfile }'; } | awk '!/\/vendor\//' | sort -u | wc -l))
GO_SOURCE_FILES   := $(strip $(shell find $(ROOT_DIR)/src -name '*.go' ! -name '*_test.go' | grep -v /vendor/ | wc -l))
JSON_SCHEMAS      := $(strip $(shell find $(ROOT_DIR)/src/contracts -name '*.schema.json' | wc -l))
BATS_TEST_FILES   := $(strip $(shell find $(ROOT_DIR)/src $(ROOT_DIR)/scripts -name '*.bats' | wc -l))
GO_TEST_FILES     := $(strip $(shell find $(ROOT_DIR)/src -name '*_test.go' | wc -l))
BATS_TESTS        := $(shell grep -rc '^@test' $(ROOT_DIR)/src $(ROOT_DIR)/scripts --include='*.bats' | awk -F: '{sum+=$$2} END {print sum}')
GO_TESTS          := $(shell grep -rc '^func Test' $(ROOT_DIR)/src --include='*_test.go' | awk -F: '{sum+=$$2} END {print sum}')

$(ROOT_DIR)/build/stats.txt: $(ROOT_DIR)/build/sources $(ROOT_DIR)/build/go-sources $(ROOT_DIR)/build/schema-sources
	@mkdir -p $(@D)
	{ \
	  echo "bash source files: $(BASH_SOURCE_FILES)"; \
	  echo "go source files: $(GO_SOURCE_FILES)"; \
	  echo "json schemas: $(JSON_SCHEMAS)"; \
	  echo "bats test files: $(BATS_TEST_FILES)"; \
	  echo "go test files: $(GO_TEST_FILES)"; \
	  echo "bats tests: $(BATS_TESTS)"; \
	  echo "go tests: $(GO_TESTS)"; \
	} > $@
