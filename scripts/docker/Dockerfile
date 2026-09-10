ARG DEBIAN_TAG=testing-slim
FROM debian:${DEBIAN_TAG}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git jq bats shellcheck \
      build-essential dpkg-dev debhelper lintian golang-any apt-utils \
 && rm -rf /var/lib/apt/lists/*

ENV GETTOKEN_DISPOSABLE_BASE=yes

WORKDIR /work
