# 19. Components speak documents

## Context

Record 13 put a contract on the wire, but nothing said what a component is or how one reaches another. The tree carried three answers at once. The boundaries with no document were the ones where something crossed from outside.

## Decision

A component reads one document from standard input and writes one to standard output, taking no arguments. The agent's entry point is the only exception.

## Motivation

A boundary with no document has nothing to hold a contract to, so the guarantee stops there and starts again on the far side. Every contract refuses what it does not name, so what may cross is stated rather than conventional. Each hop carries strictly less than the one before it: an agent says what it wants, the privileged half adds what only it can vouch for, and an exchanger is told who and what for. A signature travels no further than the component it is addressed to.
