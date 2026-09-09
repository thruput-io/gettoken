ARG DEBIAN_TAG=testing-slim
FROM debian:${DEBIAN_TAG}

# Everything both runs need: the suite reads the tree and runs the unit tests,
# the packages run builds the packages and has lintian read them.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git jq bats shellcheck \
      build-essential dpkg-dev debhelper lintian golang-any \
 && rm -rf /var/lib/apt/lists/*

ENV GETTOKEN_DISPOSABLE_BASE=yes

WORKDIR /work
ENTRYPOINT ["sh"]
