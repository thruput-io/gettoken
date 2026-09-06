.PHONY: test diagrams image validators

test:
	sh tools/integration-test-tool/test/exit-status.sh
	sh integration/integration.sh

diagrams:
	sh integration/mermaid.sh

image:
	docker build -t gettoken-test:stable  --build-arg DEBIAN_TAG=stable-slim  -f integration/docker/Dockerfile integration/docker
	docker build -t gettoken-test:testing --build-arg DEBIAN_TAG=testing-slim -f integration/docker/Dockerfile integration/docker

validators: image
	docker run --rm -v "$(CURDIR)":/work gettoken-test:stable  integration/validators/compare.sh
	docker run --rm -v "$(CURDIR)":/work gettoken-test:testing integration/validators/compare.sh
