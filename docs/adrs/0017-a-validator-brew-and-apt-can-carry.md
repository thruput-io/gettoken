# 17. A validator brew and apt can carry

## Context

Record 13 chose a validator no apt carries, and record 16 replaced it with one no brew carries. Each held one half of the same requirement. Nothing distributed by both reads the dialect the contracts declare.

## Decision

The validator is ours, built from source on both sides, in Go against a permissively licensed library that is vendored.

## Motivation

Both conditions are met by construction rather than granted by an archive, so what a distribution happens to carry stops constraining this repository. The dependency is vendored, so no build reaches the network. The toolchain brings its own formatter, vetter and test runner, so the repository gains no linter and no configuration for one. Nothing restates what a contract says: a document is handed to its schema, and what the schema said is reported.
