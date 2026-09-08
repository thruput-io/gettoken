.PHONY: check debian debian-packages images diagrams

IMAGE = gettoken-test

check:
	sh integration/suite.sh

images:
	docker build -t $(IMAGE):debian   --build-arg DEBIAN_TAG=testing-slim -f integration/docker/Dockerfile          integration/docker
	docker build -t $(IMAGE):packages --build-arg DEBIAN_TAG=testing-slim -f integration/docker/Dockerfile.packages integration/docker

debian: images
	docker run --rm -v "$(CURDIR)":/work $(IMAGE):debian integration/suite.sh

debian-packages: images
	docker run --rm -v "$(CURDIR)":/work $(IMAGE):packages integration/packages.sh

diagrams:
	sh integration/mermaid.sh
