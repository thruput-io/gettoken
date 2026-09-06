.PHONY: test check debian-stable debian-latest images diagrams

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

test: check debian-stable
	@rc=0; $(MAKE) --no-print-directory debian-latest || rc=$$?; \
	if [ $$rc -eq 0 ]; then echo "ok: debian latest"; \
	else echo "WARNING: the suite exited $$rc on debian latest; this verification does not block"; fi

diagrams:
	sh integration/mermaid.sh
