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
