# 18. Every number is bounded

## Context

Record 13 put a contract on every hop, and neither numeric field had an upper end. JSON numbers are read as floating point, so past 2^53 a value stops round-tripping. Both hops accepted such a document and neither was at fault.

## Decision

Every numeric field a contract declares carries a minimum and a maximum, taken from what the field means rather than from what the format can hold.

## Motivation

A number a contract does not bound is one it admits at any size. Bounds drawn from meaning sit far below the size at which a number stops being exact, so no document any contract admits can reach the rounding. The defect is put out of range rather than guarded against in code. Carrying the digits as written instead does not work, because the validator then reads the value as a string and refuses it as an integer.
