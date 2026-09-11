ARG DEBIAN_TAG=testing-slim
FROM debian:${DEBIAN_TAG}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      git jq bats shellcheck \
      build-essential dpkg-dev debhelper lintian golang-any \
      apt-utils gnupg \
 && rm -rf /var/lib/apt/lists/*

# The tree arrives as a mount owned by whoever checked it out, and git refuses
# a repository it reads as someone else's. The rules that read the tree with
# git grep would silently find nothing, so say the working directory is safe.
RUN git config --system --add safe.directory /work

ENV GETTOKEN_DISPOSABLE_BASE=yes

WORKDIR /work
