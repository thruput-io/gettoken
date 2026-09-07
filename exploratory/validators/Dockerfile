ARG DEBIAN_TAG=stable-slim
FROM debian:${DEBIAN_TAG}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      jsonschema-jv libjson-schema-modern-perl php-json-schema python3-jsonschema \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
ENTRYPOINT ["sh"]
