# 33. A local build is the pipeline

## Context

`agent_build.sh` was written to run the whole chain locally, in the containers
the pipeline uses. It kept its own copy of what each CI job did, the copies
drifted, and it ended up testing something CI never ran.

## Decision

Each job's work is a script, and both `verifications.yml` and `agent_build.sh`
call that script rather than describe the work again:

- `scripts/build-in-container.sh` builds the tree on `debian:testing-slim`.
- `scripts/payload.sh` is everything a clean machine is given: the packages
  and what installs and exercises them.
- `scripts/verify-in-container.sh` runs that on a clean `debian:testing-slim`.
- `src/integration-test/clean-machine.sh` is what runs on the clean machine,
  in that container, on the macOS runner and in a `macos-vm` guest alike.

## Motivation

What CI and a local run share cannot drift apart, and a green local run is a
claim about the pipeline.
