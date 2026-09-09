ARG DEBIAN_TAG=testing-slim
FROM debian:${DEBIAN_TAG}

# The builder: what it takes to lint the tree, run the unit tests, compile the
# contract component and build the packages. Nothing is verified against an
# installation here, because a base already holding a Go toolchain, debhelper and
# lintian cannot show what installing a package brought. That runs on the official
# image instead, which is a base nobody built.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git jq bats shellcheck \
      build-essential dpkg-dev debhelper lintian golang-any \
 && rm -rf /var/lib/apt/lists/*

ENV GETTOKEN_DISPOSABLE_BASE=yes

WORKDIR /work
ENTRYPOINT ["sh"]
