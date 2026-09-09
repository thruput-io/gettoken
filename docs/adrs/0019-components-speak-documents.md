# 19. Components speak documents

## Context

Record 13 put a contract on the wire, but nothing said what a component is or how one reaches another.

## Decision

A component reads one document from standard input and writes one to standard output. A component is both defined and bound by this. The agent's entry point is the only exception.

## Motivation

Our components are free to evolve independently when bound to contracts.
