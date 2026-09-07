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
the build reaches the network on no base. `brew` builds it with `go build` and so
does `debian/rules`. Both conditions are met by construction rather than granted
by an archive, and what a distribution happens to carry stops being a constraint
on this repository.

`gofmt` and `go vet` come with the toolchain. The repository gains no linter and
no configuration for one.

## Both directions

`parse` reads a document and hands back the fields the caller named. `format`
takes fields and writes the document. Both take the contract, so a document is
neither read nor written except through the contract that governs it, and the
types come from the contract rather than from the caller remembering which
fields are numbers.

`format` reads a field from a file or from standard input when it is written
`field=@path`, because a response carrying a super-token must not put it on a
command line every account on the machine can read.

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
