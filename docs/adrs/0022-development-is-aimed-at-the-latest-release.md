# 22. Development is aimed at the latest release, and every verification is mandatory

## Context

The gate ran five verifications against two Debian bases and two macOS runners,
and three of them were allowed to fail: `continue-on-error` was set for
everything not marked blocking, so the two runs against the newer base reported
red without stopping anything. A verification that cannot fail the gate is not a
verification; it is a notification nobody is obliged to read.

The `Standards-Version` review finding is what exposed the cost. The field is
meant to state the most recent Policy release the package complies with. It said
4.7.2, and 4.7.2 was raised as behind: Policy 4.7.3 was released 2025-12-23 and
4.7.4 on 2026-03-31. Both are real. The reason the field could not move is that
the blocking runs build on Debian stable, whose lintian is 2.122.0 and knows
Policy only to 4.7.2, so declaring the truth made the gate fail on the tool
rather than on the package.

The same gap runs through the whole base, and it is not a matter of taste:

| | Debian stable (trixie) | Debian testing (forky/sid) |
|---|---|---|
| debhelper | 13.24.2 | 14.3 |
| lintian | 2.122.0 | 2.139.0 |
| Go | 1.24 | 1.26 |

`debhelper-compat (= 14)` cannot be satisfied on stable at all. Neither target
was wrong; holding both was, because they disagree about what correct means and
the gate had been arranged so the older one won by being the one that could fail.

## Decision

Development is aimed at the latest release. There is one Debian base, the one
being developed against, and every verification in the gate is mandatory:
`continue-on-error` is gone and there is no blocking flag, because there is
nothing to flag.

What follows from that, and is now true:

- `Standards-Version: 4.7.4`, which is the most recent Policy release.
- `Priority` is dropped from the source stanza; Policy 4.7.3 stopped
  recommending it there.
- `debhelper-compat (= 14)`.
- `Rules-Requires-Root` is dropped; `no` is the default, and the packages
  record `root/root` either way, which was checked rather than assumed.
- `go 1.26` in `go.mod`. Declaring an older language version makes the compiler
  stamp that release's compatibility GODEBUG settings into the binary, which
  lintian reports as legacy defaults.
- The two overrides for `shared-library-lacks-prerequisites` are gone. The
  newer lintian does not raise that tag against a position-independent
  executable, and an override for a tag that never fires is itself a finding.

lintian passes on all twenty-two artefacts at `error,warning,info,pedantic,experimental`,
which is every severity it is able to report.

## What this costs

The packages can no longer be built on the current Debian stable release. That
is the price of the decision rather than an oversight: `debhelper-compat 14` does
not exist there, and no arrangement of this repository changes that. Anyone
needing to build on stable builds an older tag of this source.

It also means the gate follows a moving target. Testing changes underneath us,
and a run that passed last week can fail this week because a tool learned a new
check. That is the intended behaviour: the alternative is learning about it when
the release happens, against a larger diff, with nobody obliged to look.
