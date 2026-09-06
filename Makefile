.PHONY: test diagrams images

IMAGE = gettoken-test

images:
	docker build -t $(IMAGE):stable --build-arg DEBIAN_TAG=stable-slim  -f integration/docker/Dockerfile integration/docker
	docker build -t $(IMAGE):latest --build-arg DEBIAN_TAG=testing-slim -f integration/docker/Dockerfile integration/docker

test: images
	@echo "== host — blocks"
	sh integration/suite.sh
	@echo "== debian stable — blocks"
	docker run --rm -v "$(CURDIR)":/work $(IMAGE):stable integration/suite.sh
	@echo "== debian latest — warns"
	@rc=0; docker run --rm -v "$(CURDIR)":/work $(IMAGE):latest integration/suite.sh || rc=$$?; \
	if [ $$rc -eq 0 ]; then echo "ok: debian latest"; \
	else echo "WARNING: the suite exited $$rc on debian latest; this verification does not block"; fi

diagrams:
	sh integration/mermaid.sh
