# 8. Credential helpers

## Context

Some tools take a credential from the environment. `gh` reads `GH_TOKEN`. Others
offer only a credential helper hook.

## Decision

A package may ship a credential helper. That is the tool's own extension point,
and using it supplies what the tool needs rather than replacing the tool.

It may not prime the tool. A credential left behind in a config file or a
keyring is available to every later command, not only to the one that asked for
it.

`gettoken` returns a token. It does not return a status message in place of one.
