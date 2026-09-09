# 22. An integration test is the use-case a person types

## Context

Record 20 put the chain on installed packages and left `integration/packages.sh`
as the one run spanning components. It grew to assert the packaging, lintian, how
`apt` resolves what a package declares, which names reach `/usr/bin`, the chain,
and what a purge leaves behind — one file, one order, the chain in the middle. A
run whose coverage cannot be read off it is a run nobody can say executed.

It ran in the base that built the packages, which carries `build-essential`,
`debhelper`, `lintian` and a Go toolchain. What it showed about what `apt` drew
in, it showed on a machine already holding most of it.

And `integration/` held the lint gate and every unit test beside it, in a file
called `suite.sh`. A directory named for one kind of test held mostly another.

## Decision

An integration test is a use-case, and a use-case is what a person types. There
are three, and they are the three [README.md](../../README.md) already gives:

```sh
apt-get install -y --no-install-recommends integration-test-tool
INTEGRATIONTEST_TOKEN=$(gettoken integrationtest/ci/run); export INTEGRATIONTEST_TOKEN
integration-test-tool
```

Install the one package. Ask for the capability. Run the tool on what comes
back. It runs on an official image pulled as published, with nothing installed
onto it beforehand, because a base that already carries the chain cannot show
that installing one package brought it.

`integration-test/` holds this and nothing else.

## What this costs

This reduces what the verification asserts, which
[CONTRIBUTING.md](../../CONTRIBUTING.md) permits only through a record written
for that purpose. This is that record.

Most of what went is not lost, it is placed where it belongs:

| What | Where it goes |
|---|---|
| the lint gate, the unit runner | `scripts/`, run by `make lint` and `make test` |
| the tool refuses the super-token | the tool's own tests |
| `gettoken --list`; a capability nothing serves is refused | the components' own tests |
| lintian on the source and every package | the packaging check |
| a package declares exactly the contracts it speaks | the packaging check |
| `/usr/bin` carries the entry point and the tool alone | the packaging check |
| installing one package draws in the chain and nothing else | the packaging check |
| purging takes the packages and the store with them | the packaging check |

One check leaves the tree rather than moving. A program the agent places
earlier on `PATH` cannot stand in for one the privileged half runs: asserting it
needs `/usr/lib/gettoken` to exist, and while both halves run as one account what
it shows is that `gettoken` orders `PATH` carefully, not that a boundary held. It
is carried to
[issue 34](https://github.com/thruput-io/gettoken/issues/34#issuecomment-5604593860),
where the boundary itself is decided, and is worth reinstating with that change
rather than before it.
