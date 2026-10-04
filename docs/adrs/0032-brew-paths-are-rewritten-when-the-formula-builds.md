# 32. Brew paths are rewritten when the formula builds

## Context

The components name Debian paths, which Homebrew does not write.

## Decision

Each formula rewrites them under `HOMEBREW_PREFIX` with `inreplace` when it builds.
