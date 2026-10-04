# 33. agent_build.sh captures the pipelines

## Context

Builds are done with `make`, set up by `constants.env` and `dynamic.sh`.

## Decision

`agent_build.sh` captures locally what the GitHub pipelines do. The pipelines
call no scripts of their own.
