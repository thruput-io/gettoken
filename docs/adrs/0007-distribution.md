# 7. Distribution

## Context

The packaging has to reach the machines that need it, be updated when it
changes, and be removed cleanly when it is not wanted.

## Decision

Distribution is `apt`. `brew` is optional.

A tool is integrated by publishing a package that depends on `gettoken` and
carries what that tool needs. Installing the package makes the tool available;
removing it takes it away.

The package for `gh`:

```
gh-gettoken
  Depends: gettoken, gh

  /usr/lib/gettoken/exchangers/github
```

`/usr/bin/gh` belongs to upstream and is not touched. `gh` takes its credential
from the environment, so nothing else is needed.

Installing is a privileged act. `/usr/lib/gettoken/exchangers` is root-owned,
because `token-service` runs what it finds there with the super-token in reach.
