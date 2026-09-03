# 2. The agent never holds the super-token

## Context

An agent can be fed instructions by someone else, and an agent can simply
malfunction. Either way it does things nobody asked for.

The super-token is long-lived and carries far more authority than any single job
needs. An agent holding it would put all of that authority behind whatever it
was talked into doing.

## Decision

The agent never holds the super-token. It says what it wants, and gets back a
token narrow enough for that job and nothing else.

Accountability stays with the human. The human holds the super-token and grants
pieces of it.

This repo is retired when reasoning alone makes an agent trustworthy enough that
nobody needs to hold a super-token and hand out pieces of it.
