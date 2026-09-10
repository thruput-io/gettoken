# Contributing

## make check does not shrink

`make check` is the entry point. Every verification runs it, on the machine it
is invoked on or inside a named base.

Its scope does not decrease. Not directly, by removing or weakening what it
asserts. Not indirectly, by moving a check beyond its reach, making a case
unreachable, letting a step pass without running, or skipping anything.

Reducing it requires a record in [`docs/adrs/`](docs/adrs/) permitting that
reduction, written for that purpose. There is no other route.

Growing it needs no permission.

## Records

[`docs/adrs/`](docs/adrs/) holds decisions: a choice where an alternative was
considered and turned down. How the repository is laid out, what the words mean,
and what the system always does are in [`README.md`](README.md), not there.

## Running the suite

`make check` runs the suite where you invoke it. `make debian-stable` and
`make debian-latest` run the same suite inside a named base. The host needs `jq`, `bats`
and the validator named in [record 13](docs/adrs/0013-validating-the-wire.md):

```sh
brew install jq bats-core

version=16.9.0
curl -fsSL -o /tmp/sm.zip \
  "https://github.com/sourcemeta/jsonschema/releases/download/v${version}/jsonschema-${version}-darwin-$(uname -m).zip"
unzip -q -o -d /tmp/sm /tmp/sm.zip
install -m 755 "$(find /tmp/sm -type f -name jsonschema -perm -111 | head -1)" /usr/local/bin/jsonschema
```

The validator comes from its release rather than a Homebrew cask, at the version
[`integration/docker/Dockerfile`](integration/docker/Dockerfile) pins, so the host
and the container run the same one.

Nothing is skipped when a tool is missing. A test that cannot run fails.
