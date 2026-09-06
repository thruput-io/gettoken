.PHONY: check debian-stable debian-latest debian-packages images diagrams

IMAGE = gettoken-test

check:
	sh integration/suite.sh

images:
	docker build -t $(IMAGE):stable --build-arg DEBIAN_TAG=stable-slim  -f integration/docker/Dockerfile integration/docker
	docker build -t $(IMAGE):latest --build-arg DEBIAN_TAG=testing-slim -f integration/docker/Dockerfile integration/docker

debian-stable: images
	docker run --rm -v "$(CURDIR)":/work $(IMAGE):stable integration/suite.sh

debian-latest: images
	docker run --rm -v "$(CURDIR)":/work $(IMAGE):latest integration/suite.sh

debian-packages: images
	docker run --rm -v "$(CURDIR)":/work $(IMAGE):stable integration/packages.sh

diagrams:
	sh integration/mermaid.sh
