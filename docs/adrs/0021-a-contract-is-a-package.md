# 21. A contract is a package

## Context

Record 19 gave every boundary a contract, and packaging put all of them into one package every component depended on. That dependency holds no information and can refuse nothing. Reading and writing a document were clumped the same way.

## Decision

Each contract is its own package, and a component depends on the contracts it speaks and no others. Reading a document and writing one are separate packages.

## Motivation

The dependency graph is then the statement of what may reach what, answered at install time rather than asserted in prose. A component that grows a boundary has to declare the contract for it, which is a reviewable line rather than a silent reference. An exchanger with no business seeing a signature no longer has that contract arrive with it. A component that only reads a document no longer installs the program that writes one.
