.PHONY: check deb-stable deb-testing packages images diagrams

IMAGE = gettoken-test
TARGET = deb-testing

# What each target is built as lives in integration/targets/.
STABLE_TAG  = $(shell sed -n 's/^DEBIAN_TAG=//p' integration/targets/deb-stable)
TESTING_TAG = $(shell sed -n 's/^DEBIAN_TAG=//p' integration/targets/deb-testing)

check:
	sh integration/suite.sh

images:
	docker build -t $(IMAGE):deb-stable  --build-arg DEBIAN_TAG=$(STABLE_TAG)  -f integration/docker/Dockerfile          integration/docker
	docker build -t $(IMAGE):deb-testing --build-arg DEBIAN_TAG=$(TESTING_TAG) -f integration/docker/Dockerfile          integration/docker

deb-stable: images
	docker run --rm -v "$(CURDIR)":/work -e GETTOKEN_TARGET=deb-stable $(IMAGE):deb-stable integration/suite.sh
	docker run --rm -v "$(CURDIR)":/work -e GETTOKEN_TARGET=deb-stable $(IMAGE):deb-stable integration/packages.sh

deb-testing: images
	docker run --rm -v "$(CURDIR)":/work -e GETTOKEN_TARGET=deb-testing $(IMAGE):deb-testing integration/suite.sh
	docker run --rm -v "$(CURDIR)":/work -e GETTOKEN_TARGET=deb-testing $(IMAGE):deb-testing integration/packages.sh

# The packages themselves, left where apt can install them from.
packages: images
	docker run --rm -v "$(CURDIR)":/work $(IMAGE):$(TARGET) integration/deliver.sh $(TARGET) /work/build/packages

diagrams:
	sh integration/mermaid.sh
