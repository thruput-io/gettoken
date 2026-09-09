# 18. Every number is bounded

## Context

Record 13 put a contract on every hop and record 17 made the validator ours, but
neither said how large a number a contract admits, and both numeric fields were
written with no upper end. JSON numbers are read as `float64`, so past 2^53 a
value stops round-tripping: `format` was given `9007199254740993` and `parse`
read back `9007199254740992`, with both hops accepting the document and neither
at fault. Reaching for exactness instead does not work here, because Go's
`json.Number` carries the digits as written but the validator reads it as a
string and refuses it as an integer.

## Decision

Every numeric field a contract declares carries a minimum and a maximum, taken
from what the field means rather than from what the format can hold.

Both sit far below the size at which a JSON number stops being exact, so the
defect is put out of range by the contract rather than guarded against in
code.

## The bounds

- `ExpiresIn` is from 60 to 86400. A token expiring inside a minute is not worth
  the exchange that produced it, and a day is the longest one should live.
- `Version` is from 0 to 1000000. Zero is a secret's first version.

Both ends of both bounds are pinned by cases, and a number added without them
reopens this.

