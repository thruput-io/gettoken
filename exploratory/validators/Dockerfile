ARG DEBIAN_TAG=stable-slim
FROM debian:${DEBIAN_TAG}

ARG SOURCEMETA_VERSION=16.9.0
ARG STRANGER_VERSION=cli-v0.52.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip jq nodejs npm python3 python3-venv \
 && rm -rf /var/lib/apt/lists/*

RUN arch=$(dpkg --print-architecture) \
 && case "$arch" in \
      amd64) sm=x86_64; st=x86_64-unknown-linux-gnu ;; \
      arm64) sm=arm64;  st=aarch64-unknown-linux-gnu ;; \
      *) echo "unsupported architecture $arch" >&2; exit 1 ;; \
    esac \
 && curl -fsSL -o /tmp/sm.zip \
      "https://github.com/sourcemeta/jsonschema/releases/download/v${SOURCEMETA_VERSION}/jsonschema-${SOURCEMETA_VERSION}-linux-${sm}.zip" \
 && unzip -q -o -d /tmp/sm /tmp/sm.zip \
 && install -m 755 "$(find /tmp/sm -type f -name jsonschema -perm -111 | head -1)" /usr/local/bin/sourcemeta-jsonschema \
 && curl -fsSL -o /tmp/st.tgz \
      "https://github.com/Stranger6667/jsonschema/releases/download/${STRANGER_VERSION}/jsonschema-cli-${st}.tar.gz" \
 && tar -xzf /tmp/st.tgz -C /tmp \
 && install -m 755 "$(find /tmp -maxdepth 2 -type f -name 'jsonschema-cli*' ! -name '*.tar.gz' | head -1)" /usr/local/bin/stranger-jsonschema \
 && rm -rf /tmp/sm.zip /tmp/sm /tmp/st.tgz

RUN npm install -g ajv-cli ajv-formats

RUN python3 -m venv /opt/py \
 && /opt/py/bin/pip install --quiet jsonschema check-jsonschema \
 && ln -s /opt/py/bin/jsonschema /usr/local/bin/python-jsonschema \
 && ln -s /opt/py/bin/check-jsonschema /usr/local/bin/check-jsonschema

WORKDIR /work
ENTRYPOINT ["sh"]
