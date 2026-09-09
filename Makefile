IMAGE = gettoken-test
BASES = deb-stable deb-testing

RUN = docker run --rm -v "$(CURDIR)":/work

STABLE_TAG  = $(shell sed -n 's/^DEBIAN_TAG=//p' scripts/targets/deb-stable)
TESTING_TAG = $(shell sed -n 's/^DEBIAN_TAG=//p' scripts/targets/deb-testing)

.PHONY: lint test images packages $(BASES) readme diagrams

lint:
	sh scripts/lint.sh "$(CURDIR)"

test:
	sh scripts/suite.sh

images:
	docker build -t $(IMAGE):deb-stable  --build-arg DEBIAN_TAG=$(STABLE_TAG)  -f scripts/docker/Dockerfile scripts/docker
	docker build -t $(IMAGE):deb-testing --build-arg DEBIAN_TAG=$(TESTING_TAG) -f scripts/docker/Dockerfile scripts/docker

packages: images
	$(RUN) $(IMAGE):deb-stable  scripts/deliver.sh deb-stable  /work/build/packages/deb-stable
	$(RUN) $(IMAGE):deb-testing scripts/deliver.sh deb-testing /work/build/packages/deb-testing

deb-stable: images
	$(RUN) -e GETTOKEN_TARGET=deb-stable $(IMAGE):deb-stable scripts/suite.sh
	$(RUN) $(IMAGE):deb-stable scripts/deliver.sh deb-stable /work/build/packages/deb-stable
	$(RUN) -w /work debian:$(STABLE_TAG) sh integration-test/test.sh /work/build/packages/deb-stable
	$(RUN) -w /work debian:$(STABLE_TAG) sh scripts/packaging-check.sh /work/build/packages/deb-stable

deb-testing: images
	$(RUN) -e GETTOKEN_TARGET=deb-testing $(IMAGE):deb-testing scripts/suite.sh
	$(RUN) $(IMAGE):deb-testing scripts/deliver.sh deb-testing /work/build/packages/deb-testing
	$(RUN) -w /work debian:$(TESTING_TAG) sh integration-test/test.sh /work/build/packages/deb-testing
	$(RUN) -w /work debian:$(TESTING_TAG) sh scripts/packaging-check.sh /work/build/packages/deb-testing

readme:
	sh scripts/readme.sh "$(CURDIR)" --write

diagrams:
	sh scripts/mermaid.sh
