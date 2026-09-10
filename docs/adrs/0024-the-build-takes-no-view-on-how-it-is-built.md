# 24. The build takes no view on how it is built

## Context

`components/contract/build.sh` compiles `parse` and `format`. Everything a
packaging system has an opinion about — hardening, trimming, tags, linker flags —
has a different answer per packaging system, and each has its own reason for it.
The Debian archive expects what Debian expects; a Homebrew formula expects
whatever `std_go_args` carries that month, which is not ours to copy.

## Decision

`build.sh` states three things, because none of them is a policy: where the
binaries go, that the vendored dependency tree is what is built against, and that
no version-control status is stamped into the binary.

Everything else arrives in `GOFLAGS`, which `go` reads by itself.
`debian/rules` sets there what the archive expects of anything it ships. Run from
a checkout, `GOFLAGS` is empty and the defaults are the toolchain's own.

## Motivation

`-buildvcs=false` is not a preference. `go` stamps VCS status by asking `git`,
`git` refuses a repository owned by an account other than the one asking, and a
build inside a container is always that. The binaries carry no VCS status
anywhere, so there is nothing to lose by never asking.

Because the dependency tree is vendored into this source package, nothing the
component statically links comes from another Debian source package.
`Static-Built-Using` names those, and there are none to name, which is what
`debian/source/lintian-overrides` says.
