# 19. Components speak documents

## Context

Record 13 put a contract on the wire and record 17 made the validator ours, but
neither said what a component is or how one reaches another. The tree had drifted
into three answers at once. `gettoken` handed `token-requester` a capability as an
argument. `token-service` handed an exchanger a capability as an argument and got
two bare lines back. `secret-get` and `secret-put` took a document as an argument
and a secret on standard input. Four of the boundaries had contracts and three did
not, and the three without were the ones where something crossed from outside.

A boundary with no document has nothing to hold a contract to, so the guarantee
stops there and starts again on the far side.

## Decision

A component reads one document from standard input and writes one document to
standard output. It takes no arguments.

`gettoken` is the exception, and the only one: it is where the agent types, so it
takes what the agent typed. It turns that into a document and hands it on.

Every boundary has a contract in `contracts/`, and every contract is
`additionalProperties: false`, so what may cross a boundary is stated rather than
conventional. Each hop carries strictly less than the one before it: an agent says
what it wants, the privileged half adds who is asking and what only it can vouch
for, and an exchanger is told who and what for and nothing else. A signature is
addressed to the component it is sent to and travels no further.

## Values reach format through the environment

`parse` reads a document and writes the assignments that put its fields into shell
variables. `format` is the mirror: it is given field names, reads the variables of
those names, and writes the document.

Nothing but names is passed on a command line, and that is the point. On this
Debian base, `/proc/PID/cmdline` is `-r--r--r--` and `/proc/PID/environ` is
`-r--------`: an argument is readable by every account on the machine, and an
environment variable is readable only by the account running the process. A
super-token passed as an argument is a super-token published.

It also removes the escaping. `format` encodes, so a value carrying a quote, a
backslash or a newline goes into the document whole, and no caller has to know how
to spell JSON.

A named field whose variable is not set is a failure. No contract here has an
optional field: `ask` and `secret-get-request` each hold two shapes, and which one
is being built is said by which names are given, not by leaving something out.

## The exchanger is the outside edge

An exchanger is dropped into `/usr/lib/gettoken/exchangers` rather than shipped by
any package here, so its answer is the one document on that path that arrives from
outside anything this repository builds. `token-service` holds it to
`response.schema.json` before passing it on, which is why the lifetime bounds in
record 18 are enforced there and nowhere else.

## A failure is a status, not a field

`secret-get` answered with `found`, a boolean, and a `oneOf` existed to stop the
states that opened from being spelled wrongly. Neither state needed to exist. A
component either answers with the document its contract describes, or it exits
non-zero and says why on standard error. There is no document that means "nothing
here", so there is no way to write one wrongly.
