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
puts things at. The host needs `jq`, `bats` and the validator named in
[record 16](docs/adrs/0016-a-validator-apt-can-install.md). On Debian that is one
package; on macOS the validator comes from CPAN, which is how Perl distributes.
It needs a Perl newer than the one macOS ships, and it needs
`Getopt::Long::Descriptive`, which neither Debian nor CPAN counts as required:

```sh
apt install jq bats libjson-schema-modern-perl libgetopt-long-descriptive-perl
brew install jq bats-core perl cpanminus
"$(brew --prefix perl)/bin/perl" "$(brew --prefix cpanminus)/bin/cpanm" \
  --local-lib ~/perl5 JSON::Schema::Modern Getopt::Long::Descriptive
export PATH="$HOME/perl5/bin:$PATH" PERL5LIB="$HOME/perl5/lib/perl5"
```

Nothing is skipped when a tool is missing. A test that cannot run fails.
