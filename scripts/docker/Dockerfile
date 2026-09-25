ARG DEBIAN_TAG=testing-slim
FROM debian:${DEBIAN_TAG}

COPY constants.env /tmp/constants.env
RUN . /tmp/constants.env \
 && apt-get update \
 && apt-get install -y --no-install-recommends $DEBIAN_BUILD_DEPS \
 && rm -rf /var/lib/apt/lists/* /tmp/constants.env

ENV GETTOKEN_DISPOSABLE_BASE=yes

WORKDIR /work
