# Contributing

## make unit does not shrink

`make unit` is the entry point. Every verification runs it, on the machine it
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

A test that puts a second component under test belongs in `integration-test/`, which
is the only place allowed to span them.

## Running the suite

`make unit` runs the suite where you invoke it. `make package` builds both the
Debian package and the Homebrew formula, and `make test` installs what was built
and uses it, so only that one reaches the paths a package puts things at. What
each of them needs is declared in `config.sh`, and `make setup` installs it. The
host needs `jq`, `bats`, `shellcheck` and a Go toolchain,
which builds the contract component named in
[record 17](docs/adrs/0017-a-validator-brew-and-apt-can-carry.md):

```sh
apt install jq bats shellcheck golang-go
brew install jq bats-core shellcheck go
```

`make unit` builds `parse` and `format` before it runs anything, into a
directory it puts on `PATH`. To run one `bats` file on its own, build them first
and put them on `PATH` yourself.

The gate reads every file's first line: a script says which shell it is written
for with a shebang, and a file that is sourced rather than run says it with a
`shellcheck` directive instead.

Nothing is skipped when a tool is missing. A test that cannot run fails.

## The chain a package travels

`package` builds the packages, `packaging-check` asserts what installing and
purging one does, `publish` signs the archive and uploads it to the URL
`ARCHIVE_URL` names, `test` installs from that URL on the official image, and
`promote` moves the archive that passed from there to `PROMOTED_URL`.

Neither URL has a default. The invoker names both, so a pull request publishes
to an address of its own and only what passed is moved to the address a
`sources.list` points at.

## What a green run means

The use-case runs on the `integrationtest/ci/run` capability, on the official
image for the release and nothing put onto it first: the one tool package is
installed, the super-token goes into the store, `gettoken` is asked for the
capability, and `integration-test-tool` runs on what comes back. The same tool
refuses the super-token, asserted by the tool's own tests, so a run that
succeeds is a downgrade that happened. This is the invariant: keep it green.

The builder base verifies nothing against an installation, because a base already
holding a Go toolchain, debhelper and lintian cannot show what installing a
package brought. That is why the official image, which nobody built, is where the
use-case runs.

Beside it, `scripts/packaging-check.sh` installs that one package on the same
untouched image and asserts what `apt` drew in, that nothing else came, and that
a purge leaves nothing behind — both on disk and in `/var/log/dpkg.log`, which is
dpkg's own record of what it installed and what it removed. The two are not the
same check: a package whose files are gone while dpkg still registers it passes
the first and fails the second. `scripts/deliver.sh` has `lintian` read the source
and every package as it builds them.
