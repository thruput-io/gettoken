BASH_SOURCE_FILES := $(strip $(shell git ls-files -z --cached --others --exclude-standard | xargs -0 awk 'FNR == 1 { if (FILENAME ~ /\.(sh|bash)$$/ || /^\#!.*[\/ ](ba)?sh([ \t]|$$)/) print FILENAME; nextfile }' | grep -v -c '\.bats$$'))
BASH_SRC_FILES    := $(strip $(shell git ls-files -z --cached --others --exclude-standard src | xargs -0 awk 'FNR == 1 { if (FILENAME ~ /\.(sh|bash)$$/ || /^\#!.*[\/ ](ba)?sh([ \t]|$$)/) print FILENAME; nextfile }' | grep -v -c '\.bats$$'))
GO_PACKAGES       := $(strip $(shell find src -path '*/vendor' -prune -o -name '*.go' -exec awk '/^package / { d = FILENAME; sub(/\/[^\/]*$$/, "", d); print d, $$2; nextfile }' {} + | sort -u | wc -l))
MAKEFILES         := $(strip $(shell git ls-files -z --cached --others --exclude-standard | xargs -0 awk 'FNR == 1 { if (FILENAME ~ /(^|\/)(GNUmakefile|[Mm]akefile)$$|\.mk$$/ || /^\#!.*[\/ ]make( |$$)/) print FILENAME; nextfile }' | wc -l))
GO_SOURCE_FILES   := $(strip $(shell find src -name '*.go' ! -name '*_test.go' | grep -v /vendor/ | wc -l))
JSON_SCHEMAS      := $(strip $(shell git ls-files --cached --others --exclude-standard | grep -c '\.schema\.json$$'))
BATS_TEST_FILES   := $(strip $(shell find src scripts -name '*.bats' | wc -l))
GO_TEST_FILES     := $(strip $(shell find src -name '*_test.go' | wc -l))
BATS_TESTS        := $(shell grep -rc '^@test' src scripts --include='*.bats' | awk -F: '{sum+=$$2} END {print sum}')
GO_TESTS          := $(shell grep -rc '^func Test' src --include='*_test.go' | awk -F: '{sum+=$$2} END {print sum}')

build/stats.txt: build/sources build/go-sources build/schema-sources
	@mkdir -p $(@D)
	printf '%s\n' "bash source files: $(BASH_SOURCE_FILES)" "bash files under src: $(BASH_SRC_FILES)" \
	  "go source files: $(GO_SOURCE_FILES)" "go packages: $(GO_PACKAGES)" "makefiles: $(MAKEFILES)" \
	  "json schemas: $(JSON_SCHEMAS)" "bats test files: $(BATS_TEST_FILES)" "go test files: $(GO_TEST_FILES)" \
	  "bats tests: $(BATS_TESTS)" "go tests: $(GO_TESTS)" > $@
