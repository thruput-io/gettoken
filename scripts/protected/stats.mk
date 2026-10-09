.PHONY: FORCE
FORCE:

SHELL_SHEBANG := ^\#!.*(sh|bats)$$
MAKE_SHEBANG  := ^\#!.*make

TRACKED    = git ls-files --cached --others --exclude-standard -- $(1) | awk '!/\/vendor\//'
FIRST_LINE = $(call TRACKED) | tr '\n' '\0' | xargs -0 awk -v re='$(1)' 'FNR == 1 && $$0 ~ re { print FILENAME } { nextfile }'
COUNT      = $(strip $(shell { $(1); } | sort -u | wc -l))
TESTS      = $(strip $(shell $(call TRACKED,$(1)) | tr '\n' '\0' | xargs -0 cat | grep -c '$(2)'))
SHELL_LIST = { $(call TRACKED,'*.sh' '*.bash' '*.bats'); $(call FIRST_LINE,$(SHELL_SHEBANG)); }
MAKE_LIST  = { $(call TRACKED,':(glob)**/Makefile'); $(call FIRST_LINE,$(MAKE_SHEBANG)); }

STATS = "shell files: $(call COUNT,$(SHELL_LIST))" \
        "make files: $(call COUNT,$(MAKE_LIST))" \
        "make fragments: $(call COUNT,$(call TRACKED,'*.mk'))" \
        "go source files: $(call COUNT,$(call TRACKED,'*.go' ':!:*_test.go'))" \
        "go test files: $(call COUNT,$(call TRACKED,'*_test.go'))" \
        "go tests: $(call TESTS,'*_test.go',^func Test)" \
        "json schemas: $(call COUNT,$(call TRACKED,'*.schema.json'))" \
        "json files: $(call COUNT,$(call TRACKED,'*.json' ':!:*.schema.json'))" \
        "env files: $(call COUNT,$(call TRACKED,'*.env'))" \
        "workflow files: $(call COUNT,$(call TRACKED,'.github/workflows/*.yml'))" \
        "action files: $(call COUNT,$(call TRACKED,'.github/actions/*/action.yml'))" \
        "bats test files: $(call COUNT,$(call TRACKED,'*.bats'))" \
        "bats tests: $(call TESTS,'*.bats',^@test)" \
        "bash coverage sources: $(call COUNT,$(SHELL_LIST) | grep '^src/' | grep -v '\.bats$$')"

build/sources: FORCE
	@mkdir -p $(@D)
	git ls-files --cached --others --exclude-standard | tr '\n' '\0' | xargs -0 sha256sum > $@.new
	cmp -s $@.new $@ && rm $@.new || mv $@.new $@

build/stats.txt: build/sources
	printf '%s\n' $(STATS) > $@
