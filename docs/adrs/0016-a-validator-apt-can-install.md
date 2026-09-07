# 16. A validator apt can install

## Context

Record 13 chose `sourcemeta/jsonschema`. Record 15 packaged the components, and
a package says what it needs. That validator is not in the Debian archive, so
`gettoken-contract` could not name it: the thing every document on every hop is
checked against would have had to arrive by some other route, on every machine,
forever, with nothing to notice when it had not.

A dependency a package cannot declare is a dependency nobody is holding.

## Decision

The validator is `json-schema-eval`, from `libjson-schema-modern-perl`.

It is in Debian stable and in testing, so both bases can install it and
`gettoken-contract` can depend on it. It implements 2020-12, which is the dialect
our contracts declare. It reads the document from standard input, so a request or
a stored secret is never written to a file to be checked. It answers "this
document is invalid" and "I could not read this" with different exit statuses. It
reaches the network for nothing: a reference it has not been given is an error,
not a fetch.

The comparison behind this choice is in `exploratory/validators/`, rewritten
around installability and re-run on both bases. Of the candidates `apt` offers,
`php-json-schema` accepts a document that breaks a 2020-12 keyword,
`python3-jsonschema` cannot be told about a second schema file, and
`jsonschema-jv` answers a rejection and a failure to read with the same status.

## What it takes to install it

`json-schema-eval` is a script the library ships rather than the library itself,
and neither Debian testing nor CPAN counts what the script parses its arguments
with as required, so `libgetopt-long-descriptive-perl` is named alongside the
library everywhere the validator is installed. The script also needs a Perl that
carries `blessed` as a builtin, which is 5.36 and later; macOS ships 5.34, so the
macOS side installs a Perl before it installs the validator.

## Bundling is gone

Record 13 bundled first, because the contracts reference each other through `$id`
and no validator read them as written. `json-schema-eval` takes the schemas it
needs as arguments and resolves the reference itself, so the contracts are now
read exactly as they are committed. A step that rewrites them before anything
reads them is a step that can disagree with them.

## The signature pattern is spelled differently

`Signature` excluded the control characters with `\\uXXXX`, a regular-expression
escape that ECMA-262 defines and most engines do not implement. Perl and Go both
refuse to compile it. The same code points are now written as JSON escapes, which
every engine reads as the characters they are.

Nothing the contract accepts or refuses has changed, and the bound is now pinned
by tests: it never had any, which is how a pattern only one engine could compile
went unnoticed.
