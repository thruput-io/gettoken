# 17. A validator brew and apt can carry

## Context

Record 13 chose a validator no `apt` carries, and record 16 replaced it with one
no `brew` carries, each holding one half of the same requirement and dropping
the other. A validator has to meet two conditions and no others: it reads the
2020-12 dialect the contracts declare, and both `brew` and `apt` can distribute
it. Nothing meets both.

## Decision

The validator is ours, built from source on both sides: `components/contract`,
a Go program against `github.com/google/jsonschema-go`, which is MIT, requires
nothing else at runtime, and is vendored so the build reaches the network on no
base.

Both conditions are met by construction rather than granted by an archive, and
what a distribution happens to carry stops being a constraint on this
repository.

## What the archives offer

`check-jsonschema` is the only formula in homebrew-core that reads 2020-12 from
a command line, and Debian carries it in testing alone. `valijson` is in
homebrew-core and in Debian as `libvalijson-dev`, so it clears the distribution
condition both ways, but it is a C++ library with no command-line program and it
reads draft 7. `jsonschema-jv`, `php-json-schema`, `python3-jsonschema` and
`libjson-schema-modern-perl` are in both Debian bases and in no formula.
`sourcemeta/jsonschema` is a tap and is AGPL, which is its own question.

## How it is built

`gofmt`, `go vet` and `go test` come with the toolchain, and
`components/contract/build.sh` runs all three before it links anything. The
component states its build once and both the package and the suite call it, so
they compile the same binaries the same way. The repository gains no linter and
no configuration for one.

## What the package build does not do

`dh_dwz` is overridden to do nothing. dwz skips both binaries -- "Found
compressed .debug_abbrev section, not attempting dwz compression" -- which leaves
"Too few files for multifile optimization", and dwz exits 1 on that, which
`dh_dwz` reports as an error and aborts the build on. Removing the override was
run to get that message rather than assumed.

`dh_auto_test` is overridden to do nothing as well. Left alone it hands this tree
to the makefile buildsystem, which would run `make check`, which starts the
containers the verifications run in. The checks that belong to a package build are
the ones `build.sh` runs before it links; the ones that prove this package
installs are what `integration/packages.sh` is for.

## Both directions

`parse` reads a document and hands back the fields the caller named. `format`
takes fields and writes the document. Both take the contract, so a document is
neither read nor written except through the contract that governs it.

Neither restates what a contract says. The package names no field, carries no
domain type, and derives nothing from a schema's shape: it hands a document to
the schema and reports what the schema said. An earlier version asked the schema
what type each field had, which meant walking `properties`, `$ref`, `oneOf` and
`const` in Go — a second and thinner implementation of the thing the contracts
already are. It also read the wrong branch of a `oneOf`, which is the kind of
disagreement a restatement exists to produce.

Values go into a document as they stand. Only a string needs quoting, so the
only value `format` quotes is one that is not already JSON, and the contract
then says whether that was allowed. `who=tore` is a string because `tore` is not
JSON, and `expires_in=120` is a number because `120` is. Nothing had to be
looked up to know either.

`format` reads a value from a file, or from standard input, when the argument is
written `field@path`, because a response carrying a super-token must not put it
on a command line every account on the machine can read. A value read that way
is always a string, whatever its text happens to look like, so a secret that
reads as JSON is still a secret. The source is decided by whichever operator
comes first, so a value that merely contains an `@` is a value: `wants=@/etc/…`
asks for a capability with an odd name and is refused by the contract, rather
than reading the file and reporting what it found.

## A document exists only in held form

`Open` yields a contract, a contract yields a `Document`, and nothing else makes
one. Both ways of making one — reading JSON, or assembling values — check before
they return, so holding a `Document` is itself the proof that its contract
admitted it, and there is no unchecked document to pass on by mistake.

A `Document` is opaque and cannot be changed after it is made. The one thing it
does is answer by key, and it says whether the key was carried at all, so a
field the document does not have is not the same as one that is empty.

## Bundling is gone

Record 13 bundled first, because the contracts reference each other through `$id`
and no validator read them as written. The loader resolves those references from
the contracts directory, so the contracts are read exactly as they are committed.
A step that rewrites them before anything reads them is a step that can disagree
with them.

## The signature pattern is spelled differently

`Signature` excluded the control characters with `\uXXXX`, a regular-expression
escape that ECMA-262 defines and most engines do not implement. Perl and Go both
refuse to compile it. The same code points are now written as JSON escapes, which
every engine reads as the characters they are.

Nothing the contract accepts or refuses has changed, and the bound is now pinned
by tests: it never had any, which is how a pattern only one engine could compile
went unnoticed.
