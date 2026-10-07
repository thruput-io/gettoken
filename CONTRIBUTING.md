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
`source dynamic.sh && bash src/integration-test/test.sh`, run on a
machine that has nothing but the packages and the files the test needs — never
`make`, because `make test` needs `make` itself installed first, which is not
what a real install sees.

`./agent_build.sh` captures locally what the GitHub pipelines do. It needs
Docker, and `macos-vm` for the macOS half.

`make package` writes `build/dist/deb/`, holding every `.deb` and the `Packages`
index that makes the directory an apt archive, and `build/dist/brew/`, holding
the source tarball and one formula per package. Whatever runs the integration
test first adds what was built as a source the package manager installs from.
`ADD_ARCHIVE` in `constants.env` is the one command that does it, per platform:
the apt source for `build/dist/deb/` on Debian, the tap the formulae are copied
into on macOS. The pipeline, `agent_build.sh` and `make test` all run that
command, so nobody does it by hand. `test.sh` then installs
`integration-test-tool` alone, as a user does from the published archive and
tap. apt and brew pull the rest through the dependencies the packages declare,
so a dependency the packaging got wrong fails the test rather than being hidden
by installing every package by hand.
The version is `version.txt` with the CI run number as its last digit, `0`
locally.

No `debian/` folder is kept. Each tool says what its own packages are: a
`control.in` holding its stanzas, the debhelper lists beside it, and one `.rb.in`
per formula. `scripts/packaging.sh` assembles `debian/` and the formulae under
`build/package/` from those, from the contracts, and from `scripts/debian/`,
which holds what belongs to no tool. It does so before `dpkg` reads anything,
because `dpkg` resolves build dependencies out of `debian/control` before any
rule could act.

A component never spells out where it is installed. It names `@libdir@` or
`@datadir@`, and the Makefile beside the source fills them in from `prefix`,
with the defaults the GNU coding standards give them. The Debian rules build
for `/usr`; a formula builds for the Homebrew prefix. Run from a checkout
nothing is filled in, and the tests name the directories they need through the
environment. The store is the one thing kept outside the installation: it is
`~/secrets` of the account that runs the privileged side.

`scripts/packaging.sh` manages the dependencies, once, for both formats: a
package depends on the contracts its components speak and on the packages of the
components they pipe a document into. A tool states only what cannot be derived,
as `integration-test-tool` does of `gettoken` and of its own exchanger, and it
states it once, in its `control.in`; its formula is given the same. `lintian`
at pedantic proves what the packaging says of itself, on the source and on every
package, and nothing is overridden.

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
