# 30. Integration tests never go through make

## Context

`verifications.yml`'s Debian integration job ran `make test`, which installs `make` and `git`
before anything else. `agent_build.sh`'s clean-image stage did the same.

## Decision

Integration tests run a completely clean machine. `make test` is local environment only.

CI, and the clean-image stage of `agent_build.sh`, invoke `source dynamic.sh && bash
src/integration-test/test.sh` directly, never `make test`.

## Motivation

`make test` is completely wrong on verification and misses the whole point of it.
