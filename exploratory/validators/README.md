# Choosing a validator

Evidence behind [ADR 13](../../docs/adrs/0013-validating-the-wire.md). It runs the
candidates against this repository's own contracts, on both Debian bases, and
reports what each one did.

`valid.json` is the control. A candidate that rejects it has been invoked wrongly,
and its other results are reported as meaningless rather than scored — a wrong
flag cannot be mistaken for a verdict.

`bad-capability.json` is malformed only according to a constraint that lives
behind the `$ref` into `defs.schema.json`, so a candidate that fails to resolve it
is caught rather than credited.

To run it:

```sh
docker build -t gettoken-validators:stable  --build-arg DEBIAN_TAG=stable-slim  -f exploratory/validators/Dockerfile exploratory/validators
docker build -t gettoken-validators:testing --build-arg DEBIAN_TAG=testing-slim -f exploratory/validators/Dockerfile exploratory/validators
docker run --rm -v "$PWD":/work gettoken-validators:stable  exploratory/validators/compare.sh
docker run --rm -v "$PWD":/work gettoken-validators:testing exploratory/validators/compare.sh
```
