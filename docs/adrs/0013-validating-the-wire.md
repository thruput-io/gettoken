# 13. Validating the wire

## Context

Every hop between components carries a document. A schema that no code path
consults describes a document rather than governing it: the two drift apart and
nothing reports it.

## Decision

Documents are validated at every hop.

The validator is `sourcemeta/jsonschema`. It reads a document from standard input,
and it answers "this document is invalid" and "I could not read this" with
different exit statuses, so a caller can tell a rejection from a failure. It
reaches the network only when asked to.

Validation bundles first. The contracts reference each other through `$id`, which
resolves to a URL that does not exist, so no validator reads them as written.
Bundling inlines those references into one self-contained document.

`exploratory/` holds work that answers a question rather than work that guards the
product. The comparison behind this choice is kept in `exploratory/validators/`
and is re-run when a candidate changes or a new one appears. `make test` does not
run it.
