IMAGE   = gettoken-test
TARGET  = deb-testing
TAG     = $(shell sed -n 's/^DEBIAN_TAG=//p' scripts/targets/$(TARGET))
ARCHIVE = build/packages/$(TARGET)

RUN      = docker run --rm -v "$(CURDIR)":/work
BUILDER  = $(RUN) -e GETTOKEN_TARGET=$(TARGET) $(IMAGE):$(TARGET)
OFFICIAL = $(RUN) -w /work debian:$(TAG)

.PHONY: verify setup unit build integration-test packaging-check \
        deb-stable deb-testing lint test packages readme diagrams clean

verify: integration-test packaging-check

setup:
	docker build -t $(IMAGE):$(TARGET) --build-arg DEBIAN_TAG=$(TAG) \
	  -f scripts/docker/Dockerfile scripts/docker

unit: setup
	$(BUILDER) scripts/suite.sh

build: unit
	$(BUILDER) scripts/deliver.sh $(TARGET) /work/$(ARCHIVE)

integration-test: build
	$(OFFICIAL) sh integration-test/test.sh /work/$(ARCHIVE)

packaging-check: build
	$(OFFICIAL) sh scripts/packaging-check.sh /work/$(ARCHIVE)

deb-stable:
	$(MAKE) verify TARGET=deb-stable

deb-testing:
	$(MAKE) verify TARGET=deb-testing

packages:
	$(MAKE) build TARGET=deb-stable
	$(MAKE) build TARGET=deb-testing

lint:
	sh scripts/lint.sh "$(CURDIR)"

test:
	sh scripts/suite.sh

readme:
	sh scripts/readme.sh "$(CURDIR)" --write

diagrams:
	sh scripts/mermaid.sh

clean:
	$(RUN) -w /work debian:$(TAG) rm -rf /work/build
