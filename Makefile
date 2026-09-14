IMAGE   = gettoken-test
TARGET  = deb-testing
TAG     = $(shell sed -n 's/^DEBIAN_TAG=//p' scripts/targets/$(TARGET))
ARCHIVE = build/packages/$(TARGET)
BIN     = $(CURDIR)/build/bin

RUN      = docker run --rm -v "$(CURDIR)":/work
BUILDER  = $(RUN) -w /work -e GETTOKEN_TARGET=$(TARGET) $(IMAGE):$(TARGET)
OFFICIAL = $(RUN) -w /work debian:$(TAG)

.PHONY: unit lint check-readme contract \
        setup test-base package packaging-check publish test promote \
        deb-stable deb-testing packages readme diagrams clean

unit: lint check-readme contract
	PATH="$(BIN):$$PATH" bats --recursive components tools scripts

lint:
	./scripts/lint.sh "$(CURDIR)"

check-readme:
	./scripts/readme.sh "$(CURDIR)"

contract:
	./components/contract/build.sh "$(BIN)"

setup:
	docker build -t $(IMAGE):$(TARGET) --build-arg DEBIAN_TAG=$(TAG) \
	  -f scripts/docker/Dockerfile scripts/docker

test-base: setup
	$(BUILDER) make unit

package: test-base
	$(BUILDER) ./scripts/deliver.sh $(TARGET) /work/$(ARCHIVE)

packaging-check: package
	$(OFFICIAL) ./scripts/packaging-check.sh /work/$(ARCHIVE)

publish: packaging-check
	./scripts/publish.sh "$(CURDIR)/$(ARCHIVE)" "$(ARCHIVE_URL)"

test: publish
	$(OFFICIAL) ./integration-test/test.sh "$(ARCHIVE_URL)"

promote: test
	./scripts/promote.sh "$(ARCHIVE_URL)" "$(PROMOTED_URL)"

deb-stable:
	$(MAKE) test TARGET=deb-stable

deb-testing:
	$(MAKE) test TARGET=deb-testing

packages:
	$(MAKE) package TARGET=deb-stable
	$(MAKE) package TARGET=deb-testing

readme:
	./scripts/readme.sh "$(CURDIR)" --write

diagrams:
	./scripts/mermaid.sh

clean:
	$(RUN) -w /work debian:$(TAG) rm -rf /work/build
