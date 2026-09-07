ARG DEBIAN_TAG=stable-slim
FROM debian:${DEBIAN_TAG}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      jq bats libjson-schema-modern-perl libgetopt-long-descriptive-perl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
ENTRYPOINT ["sh"]
