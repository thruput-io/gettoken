# 5. Capabilities and entitlements

## Context

An agent has to name what it wants. A human asked to approve something has to be
able to read that name and judge it.

## Decision

A capability is a name, and it is not a secret:

```
github/thruput-io/gettoken/pr/create
```

`entitlements` is a file named for the agent, listing the capabilities that
agent has.

It is the inventory: it answers "what do I have to work with", and it is what
`gettoken --list` shows.

It is also the control: a request for a capability that is not in the file is
refused.
