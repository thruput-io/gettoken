ARG DEBIAN_TAG=stable-slim
FROM debian:${DEBIAN_TAG}

ARG SOURCEMETA_VERSION=16.9.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip jq bats \
 && rm -rf /var/lib/apt/lists/*

RUN arch=$(dpkg --print-architecture) \
 && case "$arch" in \
      amd64) sm=x86_64 ;; \
      arm64) sm=arm64 ;; \
      *) echo "unsupported architecture $arch" >&2; exit 1 ;; \
    esac \
 && curl -fsSL -o /tmp/sm.zip \
      "https://github.com/sourcemeta/jsonschema/releases/download/v${SOURCEMETA_VERSION}/jsonschema-${SOURCEMETA_VERSION}-linux-${sm}.zip" \
 && unzip -q -o -d /tmp/sm /tmp/sm.zip \
 && install -m 755 "$(find /tmp/sm -type f -name jsonschema -perm -111 | head -1)" /usr/local/bin/jsonschema \
 && rm -rf /tmp/sm.zip /tmp/sm

WORKDIR /work
ENTRYPOINT ["sh"]
