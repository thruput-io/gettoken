# 31. Distribution lives in the apt and brew repositories

## Context

Publishing grew inside gettoken until it was most of the build: a signing key,
a `gh-pages` worktree, a suite per branch, an unpublish workflow, and a local
archive server so the integration test had something to install from. None of
it is about gettoken, and the next repository that ships a package would need
all of it again.

## Decision

gettoken builds packages and releases them. It does not sign or serve them.

A merge to `main` cuts the tag `v{version.txt}.{run number}` and attaches every
`.deb`, the source tarball and every Homebrew formula to that GitHub Release.

`thruput-io/apt` and `thruput-io/brew` own distribution, for every repository
listed in their `sources.txt`. Each takes the latest release of each source with
its own token: apt builds one signed archive and deploys it to Pages, brew
commits the formulae to its tap. The signing key lives in `thruput-io/apt`
only. Neither needs write access to the repository it distributes.

Verification installs the delivered files, not a published archive. A pull
request is proven by installing the `.deb`s it built on a clean machine; the
distribution repositories prove what they publish by installing it.

The tap mirrors apt: one formula per package, with `depends_on` exactly where
apt has `Depends`.

## Motivation

Publishing is the same job for every repository, so it is done once, where the
key is. A repository that releases its files is done; whoever distributes them
pulls, so no repository holds a credential to another.
