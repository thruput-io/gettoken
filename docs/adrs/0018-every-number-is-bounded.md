# 18. Every number is bounded

## Context

Record 13 put a contract on every hop, and record 17 made the validator ours.
Neither said anything about how large a number a contract admits, and both
numeric fields were written `{ "type": "integer", "minimum": 1 }` with no upper
end.

A number a contract does not bound is one it admits at any size. JSON numbers
are read as `float64`, so past 2^53 a value stops round-tripping: `format` was
given `9007199254740993` and `parse` read back `9007199254740992`. Both hops
accepted the document and neither was at fault, which is the shape of defect a
contract exists to make impossible.

Reaching for exactness instead does not work here. Go's `json.Number` carries
the digits as written, but the validator reads it as a string and refuses it as
an integer, so the document that survives decoding is refused by its own
contract.

## Decision

Every numeric field a contract declares carries a minimum and a maximum.

The bounds come from what the field means, not from what the format can hold:

- `ExpiresIn` is from 60 to 86400. A token expiring inside a minute is not worth
  the exchange that produced it, and a day is the longest one should live.
- `Version` is from 0 to 1000000. Zero is a secret's first version.

Both sit far below the size at which a JSON number stops being exact, so no
document any contract admits can reach the rounding at all. The defect is not
guarded against in code; it is put out of range by the contract.

Both ends of both bounds are pinned by cases, and a number added without them
reopens this.
