# 31. Distribution lives in the apt and brew repositories

## Context

Publishing grew inside gettoken until it was most of the build: a signing key,
a `gh-pages` worktree, a suite per branch, an unpublish workflow, and a local
archive server so the integration test had something to install from. None of
it is about gettoken, and the next repository that ships a package would need
all of it again.

## Decision

gettoken builds packages and releases them. It does not sign or serve them.

A merge to `main` whose integration tests pass on Debian and on macOS cuts the
tag `v{version.txt}.{run number}`, attaches every `.deb`, the source tarball and
every Homebrew formula to that GitHub Release, and sends a `release` repository
dispatch to the distribution repositories. Nothing publishes on a schedule or
by hand.

`thruput-io/apt` and `thruput-io/homebrew-tap` own distribution, for every repository
listed in their `sources.txt`. On a dispatch, each takes the
latest release of each source with its own token: apt builds one signed
archive and deploys it to Pages, the tap commits the formulae. The signing key
lives in `thruput-io/apt` only.

The dispatch is sent as the org's distribution app, a GitHub App whose only
permission is Contents write on the distribution repositories. It is not the
app that sets secrets.

Verification installs the delivered files, not a published archive. A pull
request is proven by installing the `.deb`s it built on a clean machine; the
distribution repositories prove what they publish by installing it.

The tap mirrors apt: one formula per package, with `depends_on` exactly where
apt has `Depends`.

## Motivation

Publishing is the same job for every repository, so it is done once, where the
key is. A source can only say that it released; the distribution repositories
fetch what it released themselves. A GitHub App is the org's identity for one
repository acting on another, and keeping it to that one permission keeps the
key and the secrets out of the source's reach.
