# 14. Distribution on macOS

## Context

Homebrew refuses to run as root and installs into a prefix owned by whoever
installed it. Nothing it installs can be privileged, and only that account can
install anything.

## Decision

macOS distribution is `brew`.

The privileged side is the account that owns the prefix. Agent accounts run what
is installed and can change none of it.

The rule that lets an agent invoke the privileged side is installed once by a
human, because `brew` cannot write it.
