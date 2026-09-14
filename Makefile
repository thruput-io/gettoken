.DELETE_ON_ERROR:

include Makefile.$(GETTOKEN_PLATFORM)

IMAGE    = gettoken-test
TARGET   = deb-testing
TAG      = $(shell sed -n 's/^DEBIAN_TAG=//p' scripts/targets/$(TARGET))
ARCHIVE  = build/packages/$(TARGET)
LIST     = build/$(TARGET).list
REPORTS  = build/reports
COVERAGE = $(REPORTS)/coverage
SIGNING  = build/signing
BIN      = $(CURDIR)/build/bin

BASH_FLOOR = 22
GO_FLOOR   = 44

SUITE  = $(shell find components tools scripts contracts -type f)
GO_SRC = $(shell find components/contract -type f -name '*.go') \
         components/contract/go.mod components/contract/go.sum

RUN      = docker run --rm -v "$(CURDIR)":/work
BUILDER  = $(RUN) -w /work -e GETTOKEN_TARGET=$(TARGET) $(IMAGE):$(TARGET)
OFFICIAL = $(RUN) -w /work debian:$(TAG)

.PHONY: setup unit test readme clean

setup: $(SIGNING)/pubkey.gpg build/image.id
unit:  $(REPORTS)/unit.report
test:  $(REPORTS)/integration.report

$(SIGNING)/pubkey.gpg: | setup-$(GETTOKEN_PLATFORM)
	./scripts/signing-key.sh "$(CURDIR)/$(SIGNING)"

build/image.id: scripts/docker/Dockerfile scripts/targets/$(TARGET)
	@mkdir -p $(@D)
	docker build -t $(IMAGE):$(TARGET) --build-arg DEBIAN_TAG=$(TAG) \
	  -f scripts/docker/Dockerfile scripts/docker
	docker image inspect -f '{{.Id}}' $(IMAGE):$(TARGET) > $@

$(BIN)/parse $(BIN)/format: $(GO_SRC)
	./components/contract/build.sh "$(BIN)"

$(REPORTS)/lint.report: $(SUITE)
	@mkdir -p $(@D)
	./scripts/lint.sh "$(CURDIR)" > $@ 2>&1

$(REPORTS)/readme.report: $(SUITE) README.md
	@mkdir -p $(@D)
	./scripts/readme.sh "$(CURDIR)" > $@ 2>&1

$(REPORTS)/test.report: $(SUITE) $(BIN)/parse $(BIN)/format
	@mkdir -p $(@D)
	PATH="$(BIN):$$PATH" bats --recursive components tools scripts > $@

$(REPORTS)/coverage.report: $(SUITE) $(BIN)/parse $(BIN)/format
	@mkdir -p $(@D)
	PATH="$(BIN):$$PATH" kcov --include-path=components,tools,scripts \
	  --bash-parse-files-in-dir=components,tools,scripts \
	  --exclude-pattern=.bats --bash-parser=$(BASH_PARSER) \
	  $(COVERAGE) bats --recursive components tools scripts
	jq -r '.percent_covered' $(COVERAGE)/bats/coverage.json > $@

$(REPORTS)/go-coverage.report: $(GO_SRC)
	@mkdir -p $(COVERAGE)
	cd components/contract && go test -mod=vendor -coverprofile=$(CURDIR)/$(COVERAGE)/go.out ./...
	cd components/contract && go tool cover -func=$(CURDIR)/$(COVERAGE)/go.out > $(CURDIR)/$(COVERAGE)/go.func
	awk 'END { sub(/%/, "", $$3); print $$3 }' $(COVERAGE)/go.func > $@

$(REPORTS)/code-is-linted: $(REPORTS)/lint.report
	test ! -s $<
	echo "shellcheck reported nothing" > $@

$(REPORTS)/readme-is-current: $(REPORTS)/readme.report
	grep -q '^ok: ' $<
	cp $< $@

$(REPORTS)/tests-pass: $(REPORTS)/test.report
	grep -qv '^not ok' $<
	grep -c '^ok ' $< > $@

$(REPORTS)/test-has-coverage: $(REPORTS)/coverage.report $(REPORTS)/go-coverage.report
	test "$$(sed 's/\..*//' $(REPORTS)/coverage.report)" -ge $(BASH_FLOOR)
	test "$$(sed 's/\..*//' $(REPORTS)/go-coverage.report)" -ge $(GO_FLOOR)
	echo "bash $$(cat $(REPORTS)/coverage.report) go $$(cat $(REPORTS)/go-coverage.report)" > $@

$(REPORTS)/unit.report: $(REPORTS)/code-is-linted $(REPORTS)/readme-is-current \
                        $(REPORTS)/tests-pass $(REPORTS)/test-has-coverage
	cat $^ > $@
	cat $@

$(REPORTS)/base.report: build/image.id $(SUITE) $(GO_SRC)
	@mkdir -p $(@D)
	$(BUILDER) make unit GETTOKEN_PLATFORM=$(GETTOKEN_PLATFORM) > $@

$(ARCHIVE)/Packages: $(REPORTS)/base.report debian contracts
	$(BUILDER) ./scripts/deliver.sh $(TARGET) /work/$(ARCHIVE)

$(ARCHIVE)/InRelease: $(ARCHIVE)/Packages $(SIGNING)/pubkey.gpg
	$(BUILDER) ./scripts/sign.sh /work/$(ARCHIVE) /work/$(SIGNING)

$(REPORTS)/packaging-check.report: $(ARCHIVE)/InRelease
	$(OFFICIAL) ./scripts/packaging-check.sh /work/$(ARCHIVE) /work/$(SIGNING)/pubkey.gpg > $@

$(LIST): $(REPORTS)/packaging-check.report
	$(OFFICIAL) ./scripts/publish.sh /work/$(ARCHIVE) /work/$(SIGNING)/pubkey.gpg /work/$(LIST)

$(REPORTS)/integration.report: $(LIST)
	$(OFFICIAL) ./integration-test/test.sh /work/$(LIST) > $@
	cat $@

readme:
	./scripts/readme.sh "$(CURDIR)" --write

$(REPORTS)/diagrams.report: README.md scripts/mermaid.sh
	@mkdir -p $(@D)
	./scripts/mermaid.sh > $@ 2>&1

clean:
	$(RUN) -w /work debian:$(TAG) rm -rf /work/build
