ARG DEBIAN_TAG=stable-slim
FROM debian:${DEBIAN_TAG}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      jq bats shellcheck golang-go \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
ENTRYPOINT ["sh"]
