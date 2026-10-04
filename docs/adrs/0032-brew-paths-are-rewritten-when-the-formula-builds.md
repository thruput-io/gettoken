# 32. Brew paths are rewritten when the formula builds

## Context

The components name where their other halves live: `/usr/lib/gettoken`,
`/usr/share/gettoken` and the store in `/var/lib/gettoken`. Homebrew writes none
of them, so a brew install could not find itself.

## Decision

The source carries the Debian paths. Each formula's `install` rewrites the ones
in the files it installs, with `inreplace`, before anything is built:
`/usr/lib/gettoken` and `/usr/share/gettoken` become the same paths under
`HOMEBREW_PREFIX`, and `/var/lib/gettoken` becomes `var/gettoken` under it.

Nothing detects the platform at run time.

## Motivation

Paths belong to the package format, so they are settled where the package is
built, as `dpkg` settles them for apt. `HOMEBREW_PREFIX` differs between Apple
silicon and Intel, so only the formula knows it.

The store under `HOMEBREW_PREFIX/var` belongs to the account that owns brew,
which is the privileged account (ADR 26). Homebrew has no uninstall hook, so
unlike the apt package, removing the formula leaves the store behind.
