# 23. The tree is written in bash

## Context

Every script in the tree carried `#!/bin/sh` and `set -eu`. A failing stage in
the middle of a pipeline was therefore invisible: the pipeline reports what its
last stage said, and `set -e` never sees the failure.

`pipefail` is what closes that, and POSIX sh has no equivalent. `shellcheck`
refuses it in its `sh` dialect (SC3040), so the lint gate cannot be satisfied and
the rule met at the same time while the tree claims to be POSIX sh.

The tree runs on two kinds of machine: the Debian bases the packages are built
and verified in, and the macOS host a developer invokes `make test` on.

## Decision

Every script is `#!/bin/bash` with `set -euo pipefail`. That includes the seven
executables the packages ship and the maintainer script, not only the build
scripts. The lint gate reads each file's first line and checks it as bash.

## Motivation

bash is on every machine the tree runs on. It is `Essential: yes` in Debian, so
no package gains a dependency by naming it, and macOS ships it. One shell that
aborts on a failing pipeline, everywhere, is worth more than the claim of being
POSIX sh, which the chain never needed for its own sake.

Turning `pipefail` on found two pipelines that were relying on `grep` exiting 1
to mean "no match": the store's search for the highest version it holds. Both now
use `awk`, for which finding nothing is not a failure. That is the rung above
handling the status at all.

Splitting the tree — bash for what runs in a container, POSIX sh for what ships —
was turned down. It puts two conventions on the same kind of file and leaves the
shipped half without the rule.
