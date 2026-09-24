# 30. Integration tests never go through make

## Context

`verifications.yml`'s Debian integration job ran `make test`, which installs `make` and `git`
before anything else. `agent_build.sh`'s clean-image stage did the same.

## Decision

Integration tests run a completely clean machine. `make test` is for the builder, not
verification.

The verification job checks out only `constants.env`, `dynamic.sh`, and
`src/integration-test/test.sh`, and runs `source dynamic.sh && bash
src/integration-test/test.sh` inside a plain, unmodified `debian:testing-slim` container — no
`make`, no `git`, no pre-installed `ca-certificates`. `test.sh` installs everything it needs
itself, through the platform's own package manager.

## Motivation

`make test` needs `make` and the whole Makefile graph on the runner before anything installs,
which is not the clean machine a real install sees. Integration tests run a completely clean
machine.
