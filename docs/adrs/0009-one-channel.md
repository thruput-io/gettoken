# 9. One channel

## Context

An agent uses `gettoken` by substitution:

```sh
TOKEN=$(gettoken github/thruput-io/gettoken/pr/create)
```

Whatever is written to stdout is what the caller assigns. There is one channel,
and it already has a job.

## Decision

`gettoken` writes the token and nothing else.

The response document stays between `token-service` and `token-requester`. None
of it reaches the agent.

A failure writes to stderr and leaves stdout empty, so a caller cannot assign an
error message to a credential.

The agent asks again every time it needs a token. It is not told when a token
expires and does not track one. Putting that on the channel, or on `--list`,
buys complexity the agent has no use for.

Caching belongs to the privileged half.
