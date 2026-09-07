# 16. A validator brew and apt can carry

## Context

Record 13 chose `sourcemeta/jsonschema`, which no `apt` carries. Record 15
packaged the components, and a package says what it needs, so that was replaced
with `json-schema-eval` from `libjson-schema-modern-perl`, which no `brew`
carries. Each record held one half of the same requirement and dropped the other,
and the second choice cost macOS a Homebrew Perl, forty CPAN distributions and a
dependency upstream does not count as required.

A validator has to meet two conditions and no others: it reads JSON Schema, and
both `brew` and `apt` can distribute it.

Nothing meets both. `check-jsonschema` is the only JSON Schema validator in
homebrew-core, and Debian carries it in testing alone. `jsonschema-jv`,
`php-json-schema`, `python3-jsonschema` and `libjson-schema-modern-perl` are in
both Debian bases and in no formula. `sourcemeta/jsonschema` is a tap and is
AGPL, which is its own question.

## Decision

The validator is ours, built from source on both sides.

`components/contract` is a Go program against `github.com/google/jsonschema-go`,
which is MIT and requires nothing else at runtime. The dependency is vendored, so
the build reaches the network on no base. `brew` and `debian/rules` both build it
from that source. Both conditions are met by construction rather than granted
by an archive, and what a distribution happens to carry stops being a constraint
on this repository.

`gofmt`, `go vet` and `go test` come with the toolchain, and
`components/contract/build.sh` runs all three before it links anything. The
component states its build once and both the package and the suite call it, so
they compile the same binaries the same way. The repository gains no linter and
no configuration for one.

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
