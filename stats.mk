BASH_SOURCE_FILES := $(shell echo $(SHELL_FILES) | wc -w)
GO_SOURCE_FILES   := $(shell find src -name '*.go' ! -name '*_test.go' | grep -v /vendor/ | wc -l)
JSON_SCHEMAS      := $(shell find src/contracts -name '*.schema.json' | wc -l)
BATS_TEST_FILES   := $(shell find src scripts -name '*.bats' | wc -l)
GO_TEST_FILES     := $(shell find src -name '*_test.go' | wc -l)
BATS_TESTS        := $(shell grep -rc '^@test' src scripts --include='*.bats' | awk -F: '{sum+=$$2} END {print sum}')
GO_TESTS          := $(shell grep -rc '^func Test' src --include='*_test.go' | awk -F: '{sum+=$$2} END {print sum}')

build/stats.txt: build/sources build/go-sources build/schema-sources
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
