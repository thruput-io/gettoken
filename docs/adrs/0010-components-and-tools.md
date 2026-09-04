# 10. Components and tools

## Context

One repository produces many artifacts: the `gettoken` package, a package for
each integrated tool, and the image the integration test runs in. Everything
currently sits flat in `bin/`, so a second tool has nowhere to live, and nothing
in the tree says which side of the privilege boundary a file runs on.

## Decision

A **tool** is something with a command-line face. It lives under `tools/` and
owns its own privileged half, so the boundary sits inside the tool that owns it
rather than across the top of the tree.

A **component** is machinery that more than one tool shares. It lives under
`components/`.

`gettoken` is a tool, not a component. `token-requester` serves only `gettoken`,
so it is that tool's privileged half.

`contracts/` sits at the root. It is the wire between the two sides and belongs
to neither.

Unit tests live inside the component or tool they cover. `integration/` holds
only what spans them.

A component that nothing implements yet carries a file saying what it is for, so
the list stays whole and there is something to find.

```
contracts/

components/
  token-service/
  entitlements/
  notifier/                    SEAT.md
  auth-canvas/                 SEAT.md
  secret-manager/              SEAT.md
  agent-identity-authority/    SEAT.md

tools/
  gettoken/
    bin/gettoken
    privileged/token-requester
    test/  man/  packaging/
  az/
    privileged/exchanger
    test/  packaging/

integration/
```
