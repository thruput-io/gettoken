# 3. RFC 8693 token exchange

## Context

RFC 8693 describes OAuth 2.0 token exchange, and RFC 7523 describes proving who
you are with a signed JWT. Between them they define a request that asks for a
token and a response that returns one.

Our problem resembles the one they solve.

## Decision

We do not use them.

## Motivation

Following them makes our own code hard to understand. Who is asking, and what
they are doing, end up base64-encoded inside a blob, so a request cannot be read
without decoding it. Several fields can only ever hold one value: a long
identifier that means nothing to anyone here.

It also brings complexity we have no use for.

Ours says what it means:

```json
{
  "who":    "rasmus",
  "doing":  "johans-laptop/review",
  "wants":  "github/thruput-io/gettoken/pr/create",
  "signed": "host-privileged"
}
```

We recognize the resemblance, and we keep both documents for reference. In the future,
we may make use of that resemblance. Today it earns nothing.
