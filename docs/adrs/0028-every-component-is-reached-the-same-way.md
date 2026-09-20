# 28. Every component is reached the same way

## Context

Record 19 said a component reads one document from standard input and writes one
to standard output. That is a transport, and it was the only one, so reaching a
component meant building a pipeline. Every caller and every test built one, and
two components grew switches of their own — `secret-get --with-key`,
`token-requester --list` — to say which of two shapes was being handed over. A
switch is a second interface beside the document, and no contract governs it.

Standard input is also a poor place to put a privilege hop or a network. A
component that owns its own process for the length of one document cannot be a
daemon, and a component that reads its ask as it goes cannot have that ask held
to a contract before it starts.

## Decision

A component is reached through `serve`, which is the door it answers at. The
caller's half of a command line is the same for every component:

    COMPONENT [-f FILE] (PAYLOAD | --stdin)

The door says what the component is: `--request` once per shape it admits,
`--response` once, `--field` for the one value it hands over as text, and
`--answers` for the file beside it that answers. Both directions are held to
their contracts at the door, and nothing is written until the answer has been
admitted.

What answers reads one document and writes one, as record 19 says, and is told
nothing about how it was reached. Where a component admits more than one shape,
the door names the contract that admitted in `REQUEST_CONTRACT`; no component
takes a switch of its own.

A caller's words cannot describe the door: the two halves are separated by `--`,
and only what the door itself says is read from the left of it.

## Motivation

An ask that is an argument is an ask a shell, a test or another component can
make without ceremony, which is most of what a pipeline was costing.

A component that no longer owns its process is one the door can run any way it
likes. A listener on the privileged side of a boundary, or a web server in front
of the same file, changes nothing behind the door. That is what makes the
privileged half a place a daemon can stand rather than a directory a PATH
reaches into.

Holding both directions at the door is what closes the gap record 13 left: a
component validated what it read because it needed the fields, and validated
what it wrote because `format` built it, but nothing held a component to its
contracts from outside. Now the boundary is checked by the thing that is the
boundary, and a component that is replaced wholesale is held to the same
contracts as the one it replaced.

Two shapes at one door rather than a switch also puts the choice back in the
document, where a contract can govern it. `secret-get` cannot be asked for a
version by a caller that fabricated a flag; it can only be handed a document
that says so, and the store's contracts are what admit that.

A projection at the door (`--field`) keeps the agent's face text while the
privileged half speaks documents throughout. `token-requester` answers a
`token-response` and hands over `access_token`, so the lifetime stays on the
privileged side without `gettoken` having to read a document to drop it — which
would have made the entry point depend on a contract it has no business
knowing.
