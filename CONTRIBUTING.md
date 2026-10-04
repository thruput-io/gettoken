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

`make unit` runs the suite where you invoke it. `make package` builds every
format named in `PACKAGE_FORMATS`, and `make test` installs what was built and
uses it, so only that one reaches the paths a package puts things at. What each
of them needs is declared per platform in `constants.env`, and `make setup`
installs it: a Go toolchain, which builds the contract component, `bats` with
`bats-support` and `bats-assert`, `shellcheck`, `semgrep`, `kcov`, `checkmake`,
and `check-jsonschema`, and on Debian the toolchain that builds the `.deb`.

`make unit` builds `parse` and `format` before it runs anything, into a
directory it puts on `PATH`. Every check runs through a make target; there is no
other way a check is run.

The gate reads every file's first line: a script says which shell it is written
for with a shebang, and a file that is sourced rather than run says it with a
`shellcheck` directive instead.

Nothing is skipped when a tool is missing. A test that cannot run fails.

## The chain a package travels

`make build` runs the suite and builds a package in every format
`PACKAGE_FORMATS` asks for. `make test` installs what was built and uses it,
for a developer that already has a toolchain. What actually proves the chain is
`src/integration-test/clean-machine.sh`, run on a machine that has nothing but
the packages and what `scripts/payload.sh` hands it — never `make`, because
`make test` needs `make` itself installed first, which is not what a real
install sees (`docs/adrs/0030`).

`./agent_build.sh` runs the pipeline locally: the same scripts CI's jobs call,
in the same images (`docs/adrs/0033`). It needs Docker, and `macos-vm` for the
macOS half.

`make package` writes `build/dist/deb/`, holding every `.deb`, and
`build/dist/brew/`, holding the source tarball and one formula per package.
The version is `version.txt` with the CI run number as its last digit, `0`
locally.

Nothing under `debian/` that can be derived is kept. `debian/control` and one
`.install` per contract are written by `scripts/packaging.sh` from the contracts,
the components and the target, before `dpkg` reads anything, because `dpkg`
resolves build dependencies out of `debian/control` before any rule could act.
`debian/control.in` carries only what none of those know, which is prose about
the components themselves. `lintian` at pedantic proves what the packaging says
of itself, on the source and on every package.

Nothing is signed or published here (`docs/adrs/0031`). A merge to `main`
whose integration tests pass releases `build/dist` as `v{VERSION}` and tells
`thruput-io/apt` and `thruput-io/homebrew-tap`, which sign and serve the
`.deb`s and carry the formulae.

## What a green run means

The use-case runs on the `integrationtest/ci/run` capability, on the official
image for the release and nothing put onto it first: the packages that were
built are installed from the files, the super-token goes into the store, `gettoken` is asked for the
capability, and `integration-test-tool` runs on what comes back. The same tool
refuses the super-token, asserted by the tool's own tests, so a run that
succeeds is a downgrade that happened. This is the invariant: keep it green.

The builder base verifies nothing against an installation, because a base already
holding a Go toolchain, debhelper and lintian cannot show what installing a
package brought. That is why the official image, which nobody built, is where the
use-case runs.

`scripts/deliver-deb.sh` has `lintian` read the source and every package as it
builds them, down to pedantic, so what the packaging says of itself is checked
where it is written rather than after it is installed.
