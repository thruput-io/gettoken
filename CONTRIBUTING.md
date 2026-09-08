# Contributing

## make check does not shrink

`make check` is the entry point. Every verification runs it, on the machine it
is invoked on or inside a named base.

Its scope does not decrease. Not directly, by removing or weakening what it
asserts. Not indirectly, by moving a check beyond its reach, making a case
unreachable, letting a step pass without running, or skipping anything.

Reducing it requires a record in [`docs/adrs/`](docs/adrs/) permitting that
reduction, written for that purpose. There is no other route.

Growing it needs no permission.

## Records

[`docs/adrs/`](docs/adrs/) holds decisions: a choice where an alternative was
considered and turned down. How the repository is laid out, what the words mean,
and what the system always does are in [`README.md`](README.md), not there.

## Where a test lives

A unit test lives with what it covers: a component's own contracts are asserted
by that component's unit tests, because the document is the component's to
honour. Nothing central asserts a document some component owns. What is left for
a central test is what belongs to no component.

A test that puts a second component under test belongs in `integration/`, which
is the only place allowed to span them. `exploratory/` answers a question rather
than guarding the product, and `make check` does not run it.

## Running the suite

`make check` runs the suite where you invoke it. `make debian-stable` and
`make debian-latest` run the same suite inside a named base. `make debian-packages`
builds the packages inside a named base and runs the chain against them once they
are installed, which is the only verification that reaches the paths a package
puts things at. The host needs `jq`, `bats`, `shellcheck` and a Go toolchain,
which builds the contract component named in
[record 17](docs/adrs/0017-a-validator-brew-and-apt-can-carry.md):

```sh
apt install jq bats shellcheck golang-go
brew install jq bats-core shellcheck go
```

`make check` builds `parse` and `format` before it runs anything, into a
directory it puts on `PATH`. To run one `bats` file on its own, build them first
and put them on `PATH` yourself.

Nothing is skipped when a tool is missing. A test that cannot run fails.

## What a green run means

The chain runs end to end on the `integrationtest/ci/run` capability: the
super-token goes into the store, the capability is listed, a request is built,
the exchanger trades the super-token for a narrow one, `gettoken` emits that
token and nothing else, and `integration-test-tool` runs on it. The same tool
refuses the super-token, so a run that succeeds is a downgrade that happened.
This is the invariant: keep it green.

`make debian-packages` builds the packages in a base carrying nothing they run
on, has `lintian` read them, installs the one, runs the chain against what `apt`
drew in, and then purges it and fails if anything is left behind.
