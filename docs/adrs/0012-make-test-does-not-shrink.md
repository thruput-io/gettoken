# 12. `make test` does not shrink

## Context

`make test` is what a pull request check runs. It is the one thing that says
whether the system works, and a change is judged by it.

A check earns trust by what it covers, and coverage is easy to lose quietly. An
assertion is loosened to get a change through. A case is moved somewhere that
does not run. A step stops being reached. A test is skipped while something is
sorted out. Each is small, each is locally reasonable, and the check stays green
throughout.

## Decision

`make test` is the entry point, and a pull request check runs it.

Its scope does not decrease. Not directly, by removing or weakening what it
asserts. Not indirectly, by moving a check beyond its reach, making a case
unreachable, letting a step pass without running, or skipping anything.

Reducing it requires a record permitting that reduction, written for that
purpose. There is no other route.

Growing it needs no permission.
