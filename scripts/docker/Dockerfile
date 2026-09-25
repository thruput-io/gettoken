ARG DEBIAN_TAG=testing-slim
FROM debian:${DEBIAN_TAG}

# Reads DEBIAN_BUILD_DEPS from constants.env directly -- the one place that names it --
# instead of taking it as a build arg, so this can never drift from what dynamic.sh
# resolves for a real Debian build, and building this image needs nothing from the
# invoking shell's environment.
COPY constants.env /tmp/constants.env
RUN . /tmp/constants.env \
 && apt-get update \
 && apt-get install -y --no-install-recommends $DEBIAN_BUILD_DEPS \
 && rm -rf /var/lib/apt/lists/* /tmp/constants.env

ENV GETTOKEN_DISPOSABLE_BASE=yes

WORKDIR /work
