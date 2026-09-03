# 1. Package human tools for agents

## Context

The tools an agent needs already exist. They were built by humans, for humans.
`gh auth login` opens a browser and waits for someone to type. A package manager
expects an operator. Each of them asks for a person at the moment of use, and
that is what stops an agent from using them.

## Decision

We package the tools humans already built. We write no new tooling.

The test for anything we add: does it **replace** the tool, or does it **supply
what the tool needs**?

Replacing is the parallel path. An MCP server stands where the tool stood, and
then it has to keep up with everything that tool can do. It is a second stack,
used only by agents, paid for once per tool on top of the tool that already
works.

Supplying is packaging. `gettoken` hands over the credential the tool was going
to ask a human for, and then gets out of the way. The agent runs the real `gh`.

We take the second path. It stays close to the one humans already use.
