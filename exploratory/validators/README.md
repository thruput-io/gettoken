# Choosing a validator

Evidence behind [ADR 16](../../docs/adrs/0016-a-validator-apt-can-install.md), and
before it [ADR 13](../../docs/adrs/0013-validating-the-wire.md). It runs the
candidates against this repository's own contracts, on both Debian bases, and
reports what each one did.

The criterion that reopened it is installability. Packaging the components meant
declaring what each one needs, and the validator record 13 chose is not in the
Debian archive, so no package could name it. Every candidate here is one `apt`
installs, and the image builds by installing them — a candidate that cannot be
installed on a base does not appear in that base's run.

The contracts are read as they are written. There is no bundling step, because a
step that rewrites the contracts before anything reads them is a step that can
disagree with them.

`valid.json` is the control. A candidate that rejects it has been invoked wrongly,
and its other results are reported as meaningless rather than scored — a wrong
flag cannot be mistaken for a verdict.

`bad-capability.json` is malformed only according to a constraint that lives
behind the `$ref` into `defs.schema.json`, so a candidate that fails to resolve it
is caught rather than credited.

`wrong-dialect.json` breaks `dependentRequired`, which is 2020-12 and nothing
earlier. Our contracts declare 2020-12. A candidate that accepts it is reading
them in a dialect they do not claim, and what else it passes over in silence is
not knowable from our fixtures.

## What the runs showed

`json-schema-eval`, from `libjson-schema-modern-perl`, is the only candidate that
clears every bar: it fails closed on every fixture, implements the dialect the
contracts declare, resolves the reference between them on its own, reads the
document from standard input, and answers a rejection and a failure to read with
different exit statuses.

`validate-json`, from `php-json-schema`, fails closed on our fixtures and tells
those two statuses apart, but accepts `wrong-dialect.json`. It is not reading
2020-12.

`jsonschema`, from `python3-jsonschema`, cannot be told about a second schema
file, so it cannot resolve the reference between our contracts at all and rejects
the control.

`jv`, from `jsonschema-jv`, answers a rejection and a failure to read with the
same status. It also needs `--map` to keep the reference off the network, and
that flag arrived in 6.0, so on a base carrying 5.x it reaches for
`https://thruput.io/gettoken/defs.schema.json` and the run reports the control
rejected.

Two candidates were dropped before this run rather than scored in it. The
validator record 13 chose is not in the archive, which is the whole reason for
the re-run. `check-jsonschema` is, but only in testing, and the verification that
blocks runs on stable.

## To run it

```sh
docker build -t gettoken-validators:stable  --build-arg DEBIAN_TAG=stable-slim  -f exploratory/validators/Dockerfile exploratory/validators
docker build -t gettoken-validators:testing --build-arg DEBIAN_TAG=testing-slim -f exploratory/validators/Dockerfile exploratory/validators
docker run --rm -v "$PWD":/work gettoken-validators:stable  exploratory/validators/compare.sh
docker run --rm -v "$PWD":/work gettoken-validators:testing exploratory/validators/compare.sh
```
