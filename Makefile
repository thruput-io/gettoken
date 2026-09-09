.PHONY: check readme deb-stable deb-testing packages images diagrams

IMAGE = gettoken-test
TARGET = deb-testing

# What each target is built as lives in scripts/targets/.
STABLE_TAG  = $(shell sed -n 's/^DEBIAN_TAG=//p' scripts/targets/deb-stable)
TESTING_TAG = $(shell sed -n 's/^DEBIAN_TAG=//p' scripts/targets/deb-testing)

check:
	sh scripts/suite.sh

images:
	docker build -t $(IMAGE):deb-stable  --build-arg DEBIAN_TAG=$(STABLE_TAG)  -f scripts/docker/Dockerfile          scripts/docker
	docker build -t $(IMAGE):deb-testing --build-arg DEBIAN_TAG=$(TESTING_TAG) -f scripts/docker/Dockerfile          scripts/docker

deb-stable: images
	docker run --rm -v "$(CURDIR)":/work -e GETTOKEN_TARGET=deb-stable $(IMAGE):deb-stable scripts/suite.sh
	docker run --rm -v "$(CURDIR)":/work -e GETTOKEN_TARGET=deb-stable $(IMAGE):deb-stable integration-test/packages.sh

deb-testing: images
	docker run --rm -v "$(CURDIR)":/work -e GETTOKEN_TARGET=deb-testing $(IMAGE):deb-testing scripts/suite.sh
	docker run --rm -v "$(CURDIR)":/work -e GETTOKEN_TARGET=deb-testing $(IMAGE):deb-testing integration-test/packages.sh

# README says what the tree holds, so the tree writes that part of it.
readme:
	sh scripts/readme.sh "$(CURDIR)" --write

# The packages themselves, left where apt can install them from.
packages: images
	docker run --rm -v "$(CURDIR)":/work $(IMAGE):$(TARGET) scripts/deliver.sh $(TARGET) /work/build/packages

diagrams:
	sh scripts/mermaid.sh
