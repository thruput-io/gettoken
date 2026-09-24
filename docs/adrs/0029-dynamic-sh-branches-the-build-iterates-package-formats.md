# 29. dynamic.sh branches, the build iterates PACKAGE_FORMATS

## Context

The build had grown an explosion of ways to be configured, and agents hid
failing tests and linting behind code so complex that nobody could follow it.

## Decision

All conditional logic happens in `dynamic.sh`. Everything outside it is linear.

`dynamic.sh` reads `constants.env`, decides by operating system and by whether
it runs under CI, and exposes the result as `build/config.mk`. `ROOT_DIR` is
supplied by the caller — the Makefile, CI, `agent_build.sh` — because the
configuration has to work outside `make` in real life, and `dynamic.sh`
validates what it is given. `ARCHIVE_SIGNING_KEY` is provided by CI/CD; no
variables are added on top of it.

`PACKAGE_FORMATS` names the package formats a build produces. Only certain
operating systems can build certain formats, and the variants that exist are
listed in `constants.env`, one per operating system; `dynamic.sh` exposes the
one for the machine it runs on.

`PACKAGE_FORMATS` is the only thing the build branches on. Nothing is derived
from it: a derived variable gets a life of its own and fools us into supporting
combinations that never exist. Every consumer loops over `PACKAGE_FORMATS` with a
case per format. We pretend to handle every format, and the arms that never
execute stay unexecuted because we never configure it that way.
`PACKAGE_FORMATS` will hold many more formats in future.

We develop on macOS, so macOS does everything brew can provide — dpkg,
reprepro, and so forth. Where brew cannot provide it any more, the cut is made
by iterating `PACKAGE_FORMATS`. There is no reason to do all of it on a Mac; the
rest is left to CI/CD, building on Linux.

Every script is `#!/usr/bin/env bash`, not `#!/bin/bash`: macOS constantly
throws you back to `/bin/bash`, which is too old.

## Motivation

Making development easy.
