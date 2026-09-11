IMAGE   = gettoken-test
TARGET  = deb-testing
TAG     = $(shell sed -n 's/^DEBIAN_TAG=//p' scripts/targets/$(TARGET))
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
SUITE   = $(BRANCH)/$(TARGET)
PACKAGES = build/packages/$(TARGET)
ARCHIVE = build/archive
KEY     = build/signing-key.asc
ARCHIVE_URL ?= http://archive
SITE_URL ?=
BIN     = $(CURDIR)/build/bin

RUN      = docker run --rm -v "$(CURDIR)":/work
BUILDER  = $(RUN) -w /work -e GETTOKEN_TARGET=$(TARGET) $(IMAGE):$(TARGET)
OFFICIAL = -v "$(CURDIR)":/work -w /work debian:$(TAG)
SERVED   = ./scripts/served.sh "$(CURDIR)/$(ARCHIVE)"

.PHONY: test lint check-readme contract unit \
        verify named setup test-base build archive archive-unit publish unpublish \
        integration-test packaging-check \
        deb-stable deb-testing packages readme diagrams clean

test: lint check-readme unit

lint:
	./scripts/lint.sh "$(CURDIR)"

check-readme:
	./scripts/readme.sh "$(CURDIR)"

contract:
	./components/contract/build.sh "$(BIN)"

unit: contract
	PATH="$(BIN):$$PATH" bats --recursive --filter-tags '!debian' components tools scripts

verify: archive archive-unit integration-test packaging-check

archive-unit:
	$(BUILDER) bats --recursive --filter-tags debian scripts

named:
	case "$(BRANCH)" in \
	  ''|HEAD) echo "the suite has no branch to be named after; pass BRANCH=" >&2; exit 1 ;; \
	esac

setup:
	docker build -t $(IMAGE):$(TARGET) --build-arg DEBIAN_TAG=$(TAG) \
	  -f scripts/docker/Dockerfile scripts/docker

test-base: setup
	$(BUILDER) make test

build: test-base
	$(BUILDER) ./scripts/deliver.sh $(TARGET) /work/$(PACKAGES)

$(KEY): setup
	$(BUILDER) ./scripts/signing-key.sh /work/$(KEY)

archive: named build $(KEY)
	$(BUILDER) ./scripts/archive.sh /work/$(PACKAGES) /work/$(ARCHIVE) $(SUITE) /work/$(KEY)
	$(BUILDER) ./scripts/sources.sh /work/$(ARCHIVE) $(SUITE) $(ARCHIVE_URL)

publish: named
	./scripts/publish.sh $(ARCHIVE) $(BRANCH) $(SITE_URL)

unpublish: named
	./scripts/unpublish.sh $(BRANCH)

integration-test:
	$(SERVED) $(OFFICIAL) ./integration-test/test.sh $(ARCHIVE_URL) $(SUITE)

packaging-check:
	$(SERVED) $(OFFICIAL) ./scripts/packaging-check.sh $(ARCHIVE_URL) $(SUITE)

deb-stable:
	$(MAKE) verify TARGET=deb-stable

deb-testing:
	$(MAKE) verify TARGET=deb-testing

packages:
	$(MAKE) archive TARGET=deb-stable
	$(MAKE) archive TARGET=deb-testing

readme:
	./scripts/readme.sh "$(CURDIR)" --write

diagrams:
	./scripts/mermaid.sh

clean:
	$(RUN) -w /work debian:$(TAG) rm -rf /work/build
