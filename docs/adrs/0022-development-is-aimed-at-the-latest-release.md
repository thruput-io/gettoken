# 22. Every verification is mandatory, and the packaging is aimed at the latest release

## Context

The gate ran five verifications and let three of them fail. `continue-on-error`
was set for everything not marked blocking, so the runs against the newer base
reported red without stopping anything. A verification that cannot fail the gate
is a notification nobody is obliged to read.

The `Standards-Version` finding is what that cost. The field names the most
recent Policy release the package complies with. It said 4.7.2 and was raised as
behind: 4.7.3 was released 2025-12-23 and 4.7.4 on 2026-03-31, both real. The
field could not move because the runs allowed to fail the gate built on Debian
stable, whose lintian is 2.122.0 and knows Policy only to 4.7.2. The gate would
have failed on the tool rather than on the package, and the older base won by
being the one that counted.

The bases disagree, and not about taste:

| | Debian stable (trixie) | Debian testing (forky/sid) |
|---|---|---|
| debhelper | 13.24.2 | 14.3 |
| lintian | 2.122.0 | 2.139.0 |
| Go | 1.24 (the archive ceiling) | 1.26, and 1.27 |

## Decision

Every verification in the gate is mandatory. There is no blocking flag and no
`continue-on-error`, because there is nothing to flag: four runs, all of which
stop the gate.

The four are not interchangeable, and separating what each one answers is what
lets them all pass at once:

- **macOS** and **Debian stable** and **Debian latest** run the suite. They
  compile the contract component and run every unit test. None of them builds a
  package, so none of them reads `debian/control`.
- **Debian packages** builds the packages and has lintian read them. It is the
  only run that cares which debhelper or lintian exists, so it is the only one
  the packaging has to satisfy, and it runs on the release being developed
  against.

So the packaging states the truth: `Standards-Version: 4.7.4`, no `Priority` in
the source stanza, `debhelper-compat (= 14)`, and no `Rules-Requires-Root`,
whose `no` is now the default and which the packages record as `root/root`
either way — checked rather than assumed. lintian passes on all twenty-two
artefacts at `error,warning,info,pedantic,experimental`, every severity it can
report.

## The language version is not a free parameter

`go.mod` says `go 1.24`, and that is decided by the oldest base in the gate
rather than chosen. Debian stable carries `golang-1.24` and nothing newer;
backports offers nothing newer either. Reaching past it means fetching a
toolchain from outside Debian, at which point the run stops answering the
question it exists to answer.

The packages run cannot take that route in any case: `Build-Depends: golang-any`
means an archive build compiles with the distribution's toolchain, so verifying
with a hand-installed one would verify a build Debian will never perform.

A newer toolchain compiling a module that declares an older language version
stamps that release's compatibility `GODEBUG` settings into the binary, which
the newer lintian reports as legacy defaults. It cannot be answered with
`//go:debug` either: Go 1.24 rejects the settings the tag names, including
`containermaxprocs`, which arrived in 1.25. So `gettoken-parse` and
`gettoken-format` each carry an override saying the language version is held at
what the oldest base can compile, and why raising it would not make these two
programs safer — neither opens a socket, reads a certificate or resolves a URL.

That override is the visible price of keeping Debian stable in the gate. It goes
away by itself when stable is a release that carries a newer Go.

## What this costs

The packages cannot be built on Debian stable: `debhelper-compat 14` does not
exist there. Building on stable means building an older tag of this source. The
suite still runs there, so the components are still verified on stable; what is
not verified there is the packaging.

The gate also follows a moving target. Testing changes underneath us, and a run
that passed last week can fail this week because a tool learned a new check.
That is intended. The alternative is learning about it at release time, against
a larger diff, with nobody obliged to look.
