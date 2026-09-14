# 27. Platform by makefile

## Decision

`Makefile.{GETTOKEN_PLATFORM}` contains the platform-specific variables and
targets.

Nowhere in the code is `GETTOKEN_PLATFORM` tested to discover what the current
context is. A value that differs is stored in `Makefile.{GETTOKEN_PLATFORM}`
and passed via a make target.

A platform-specific target is invoked through a target dependency. For example,
the abstract target `lint` in the main Makefile depends on
`lint-{GETTOKEN_PLATFORM}`.

`GETTOKEN_PLATFORM` is the only variable allowed to denote the building or
target context, rather than calling `uname` or any alternative thereof. You can
pass it on to new contexts, but never call it by another name or mutate it.

`GETTOKEN_PLATFORM` is set by the invoker. The invoker is not part of this
repository.

The Dockerfile describing each `GETTOKEN_PLATFORM` is built by make as well. The
same rules can handle platform-specific Dockerfiles.

## Motivation

Each build is a completely linear and deterministic process without any branches.
By having no logic, it cannot fail from logical errors. Platform differences are
clearly and explicitly handled by the Makefile. Adding a new platform will be
straightforward, as everything that differs from one platform to another is listed
in `Makefile.{GETTOKEN_PLATFORM}`.

There is no default value on variables that gets overridden by the platform-specific
one. If one platform requires a separate value, it must go into all
`Makefile.{GETTOKEN_PLATFORM}` files.

