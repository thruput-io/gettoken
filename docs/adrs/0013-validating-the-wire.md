# 13. Validating the wire

## Context

Every hop between components carries a document. A schema that no code path
consults describes a document rather than governing it: the two drift apart and
nothing reports it.

## Decision

Documents are validated at every hop.