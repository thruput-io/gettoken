# 21. A contract is a package

## Context

Record 19 made every boundary carry a document and gave every boundary a
contract. Packaging then put all thirteen contracts, and both programs that
carry a document through one, into a single `gettoken-contract` package that
every component depended on.

That package says nothing. Every component depends on it, so the dependency
holds no information: it cannot be read to learn which documents a component
speaks, and it cannot refuse anything, because installing any component
installs every contract whether that component may speak it or not. An
exchanger is told who is asking and what for and deliberately not what the
request was signed with, but the package carrying the signature's contract
arrived with it anyway.

Clumping `parse` and `format` together has the same shape. They are two
directions, and a component that only ever reads a document was made to install
the program that writes one.

## Decision

Each contract is its own package. `gettoken-contract-defs` carries the shapes
the others are built from, and each contract that references it depends on it;
`agent-list-request` does not reference it and does not depend on it.

A component depends on the contracts it speaks and no others, so the dependency
graph is the statement of what may reach what. `gettoken-secret-manager`
depends on the five documents the store reads and writes.
`integration-test-tool` depends on the four its exchanger says and is told, and
on no contract carrying a signature.

`parse` and `format` are separate packages, and neither carries a contract.

## What this buys

Asking `apt` what a package depends on is asking what it is allowed to say and
be told, and that answer is checked at install time rather than asserted in a
document. A component that grows a new boundary has to declare the contract for
it, which is a reviewable line in `debian/control` rather than a silent new
reference resolved out of a directory that already held everything.

Twenty binary packages are built where six were. That is the cost, and it is
paid by the packaging rather than by anyone installing: installing
`integration-test-tool` still names one package and `apt` draws in the rest.
