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
and is re-run when a candidate changes or a new one appears. `make check` does not
run it.

## Every number is bounded

A number a contract does not bound is one it admits at any size, and JSON numbers
are read as `float64`, so past 2^53 a value stops round-tripping: a document
written with `9007199254740993` reads back as `9007199254740992`. Two hops then
disagree about a value both of them accepted, and neither is at fault.

Both numeric fields carry a minimum and a maximum, taken from what the field
means rather than from what the format happens to hold:

- `ExpiresIn` is from 60 to 86400. A token that expires inside a minute is not
  worth the exchange that produced it, and a day is the longest one should live.
- `Version` is from 0 to 1000000. Zero is a secret's first version.

Both bounds sit far below the size at which a JSON number stops being exact, so
no document any contract admits can reach the rounding at all. The defect is not
guarded against; it is put out of range.

Every numeric field the contracts declare carries both bounds, and both ends of
both are pinned by cases. A number added without them reopens this.
