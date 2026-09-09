# 16. A validator apt can install

## Context

Record 13 chose a validator the Debian archive does not carry. Record 15 made every component a package, and a package says what it needs. A dependency a package cannot declare is a dependency nobody is holding.

## Decision

The validator is json-schema-eval, from libjson-schema-modern-perl.

## Motivation

It is in Debian stable and in testing, so the dependency is declared rather than assumed to be present. It implements the dialect the contracts declare. It reads the document from standard input, so a request or a stored secret is never written to a file to be checked. It answers an invalid document and an unreadable one with different statuses. It reaches the network for nothing, so a reference it was not given is an error rather than a fetch.
