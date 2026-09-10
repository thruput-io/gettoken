IMAGE   = gettoken-test
TARGET  = deb-testing
TAG     = $(shell sed -n 's/^DEBIAN_TAG=//p' scripts/targets/$(TARGET))
ARCHIVE = build/packages/$(TARGET)
BIN     = $(CURDIR)/build/bin

RUN      = docker run --rm -v "$(CURDIR)":/work
BUILDER  = $(RUN) -w /work -e GETTOKEN_TARGET=$(TARGET) $(IMAGE):$(TARGET)
OFFICIAL = $(RUN) -w /work debian:$(TAG)

.PHONY: test lint check-readme contract unit \
        verify setup test-base build integration-test packaging-check \
        deb-stable deb-testing packages readme diagrams clean

test: lint check-readme unit

lint:
	./scripts/lint.sh "$(CURDIR)"

check-readme:
	./scripts/readme.sh "$(CURDIR)"

contract:
	./components/contract/build.sh "$(BIN)"

unit: contract
	PATH="$(BIN):$$PATH" bats --recursive components tools scripts

verify: integration-test packaging-check

setup:
	docker build -t $(IMAGE):$(TARGET) --build-arg DEBIAN_TAG=$(TAG) \
	  -f scripts/docker/Dockerfile scripts/docker

test-base: setup
	$(BUILDER) make test

build: test-base
	$(BUILDER) ./scripts/deliver.sh $(TARGET) /work/$(ARCHIVE)

integration-test: build
	$(OFFICIAL) ./integration-test/test.sh /work/$(ARCHIVE)

packaging-check: build
	$(OFFICIAL) ./scripts/packaging-check.sh /work/$(ARCHIVE)

deb-stable:
	$(MAKE) verify TARGET=deb-stable

deb-testing:
	$(MAKE) verify TARGET=deb-testing

packages:
	$(MAKE) build TARGET=deb-stable
	$(MAKE) build TARGET=deb-testing

readme:
	./scripts/readme.sh "$(CURDIR)" --write

diagrams:
	./scripts/mermaid.sh

clean:
	$(RUN) -w /work debian:$(TAG) rm -rf /work/build
