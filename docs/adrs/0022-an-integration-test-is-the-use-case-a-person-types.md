# 22. An integration test is the use-case a person types

## Context

`integration/packages.sh` was one run asserting the packaging, lintian, how apt
resolves what a package declares, which names reach `/usr/bin`, the chain, and
what a purge leaves behind, and what it covered could not be read off it. It ran
in the base that built the packages, which carries `build-essential`,
`debhelper`, `lintian` and a Go toolchain, so what it showed about what apt drew
in it showed on a machine already holding most of it. `integration/` held the
lint gate and every unit test beside it, in a file called `suite.sh`.

## Decision

An integration test is a use-case, a use-case is what a person types, and there
are three: install the one tool package, ask for the capability, and run the
tool on what comes back, on an official image with nothing installed onto it
first. `integration-test/` holds that and nothing else.

## What this costs

This reduces what the verification asserts, which
[CONTRIBUTING.md](../../CONTRIBUTING.md) permits only through a record written
for that purpose. This is that record. Most of what goes moves left rather than
sideways, because a safeguard belongs on the leftmost rung that can catch it and
an installed system is the rightmost there is:

| What | Where it goes |
|---|---|
| the lint gate, the unit runner | `scripts/`, behind `make lint` and `make test` |
| every shell file passes the lint gate | the lint gate already; the packaged run asserted it twice |
| `/usr/bin` carries the entry point and the tool alone | a test reading what the packaging installs |
| `gettoken --list`; a capability nothing serves is refused | the components' own tests |
| the tool refuses the super-token | the tool's own tests |
| the store's path and its mode | the store's own tests |
| lintian on the source and on every package | stays with the build, because it reads built packages |
| a purge meeting something it does not own says so, and still succeeds | stays on a disposable machine, because it removes real paths |

Two checks are dropped. What a package draws in was asserted by installing it
and diffing what was there before against after, which is the last place to
learn a fact the packaging settles first and the only place the check can pass
by failing quietly. Reading back off a built package that it declares exactly
the contracts its executables speak asserts that the generator and dpkg did what
they say, not that the declaration is right. Declaring too little still fails on
its own, because apt will not resolve a dependency that is not there; declaring
too much is now caught by nothing, which is the cost, and record 21 is the
reasoning it weakens.

One check leaves the tree rather than moving. Asserting that a program the agent
places earlier on `PATH` cannot stand in for one the privileged half runs needs
`/usr/lib/gettoken` to exist, and while both halves run as one account it shows
that `gettoken` orders `PATH` carefully rather than that a boundary held. It
waits on the boundary itself being decided.
