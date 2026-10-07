BASH_SOURCE_FILES := $(strip $(shell git ls-files -z --cached --others --exclude-standard | xargs -0 awk 'FNR == 1 { if (FILENAME ~ /\.(sh|bash)$$/ || /^\#!.*[\/ ](ba)?sh([ \t]|$$)/) print FILENAME; nextfile }' | grep -v -c '\.bats$$'))
BASH_SRC_FILES    := $(strip $(shell git ls-files -z --cached --others --exclude-standard src | xargs -0 awk 'FNR == 1 { if (FILENAME ~ /\.(sh|bash)$$/ || /^\#!.*[\/ ](ba)?sh([ \t]|$$)/) print FILENAME; nextfile }' | grep -v -c '\.bats$$'))
GO_PACKAGES       := $(strip $(shell find src -path '*/vendor' -prune -o -name '*.go' -exec awk '/^package / { d = FILENAME; sub(/\/[^\/]*$$/, "", d); print d, $$2; nextfile }' {} + | sort -u | wc -l))
MAKEFILES         := $(strip $(shell git ls-files --cached --others --exclude-standard | grep -c -E '(^|/)(GNUmakefile|[Mm]akefile)$$|\.mk$$'))
GO_SOURCE_FILES   := $(strip $(shell find src -name '*.go' ! -name '*_test.go' | grep -v /vendor/ | wc -l))
JSON_SCHEMAS      := $(strip $(shell git ls-files --cached --others --exclude-standard | grep -c '\.schema\.json$$'))
BATS_TEST_FILES   := $(strip $(shell find src scripts -name '*.bats' | wc -l))
GO_TEST_FILES     := $(strip $(shell find src -name '*_test.go' | wc -l))
BATS_TESTS        := $(shell grep -rc '^@test' src scripts --include='*.bats' | awk -F: '{sum+=$$2} END {print sum}')
GO_TESTS          := $(shell grep -rc '^func Test' src --include='*_test.go' | awk -F: '{sum+=$$2} END {print sum}')

build/stats.txt: build/sources build/go-sources build/schema-sources
	@mkdir -p $(@D)
	{ \
	  echo "bash source files: $(BASH_SOURCE_FILES)"; \
	  echo "bash files under src: $(BASH_SRC_FILES)"; \
	  echo "go source files: $(GO_SOURCE_FILES)"; \
	  echo "go packages: $(GO_PACKAGES)"; \
	  echo "makefiles: $(MAKEFILES)"; \
	  echo "json schemas: $(JSON_SCHEMAS)"; \
	  echo "bats test files: $(BATS_TEST_FILES)"; \
	  echo "go test files: $(GO_TEST_FILES)"; \
	  echo "bats tests: $(BATS_TESTS)"; \
	  echo "go tests: $(GO_TESTS)"; \
	} > $@
