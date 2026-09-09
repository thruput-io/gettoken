# 20. The chain is verified against installed packages

## Context

`integration/integration.sh` put seven directories of the checkout on `PATH` and
reached `token-requester`, `token-service`, `entitlements`, `secret-put`,
`secret-get`, `parse` and `format` by name, none of which is a public name in
what is shipped. It therefore drove a checkout through entry points no installed
system offers, and it was the run `make check` executed, while
`integration/packages.sh` already installs `integration-test-tool` alone and
exercises the chain a machine would have. Most of what `integration.sh` asserted
was not about the chain but one component's behaviour, which is a unit test and
belongs with the component.

## Decision

The chain is exercised in one place, against installed packages, by `chain_runs`
in `integration/chain.sh` called from `integration/packages.sh`, and
`integration/integration.sh` is deleted.

What it asserted about a single component moved into that component's own tests,
and the `PATH` sabotage check moved into `chain_runs`, so it now runs where
`/usr/lib/gettoken` actually exists rather than where it does not.

## What this costs

This reduces what `make check` runs, which
[CONTRIBUTING.md](../../CONTRIBUTING.md) permits only through a record written
for that purpose. This is that record.

`make check` no longer exercises the chain end to end. It runs the lint gate,
builds the contract component, and runs every unit test, including the cases
that moved out of `integration.sh`. The chain runs under `make debian-packages`,
which is blocking in CI.

The cost is macOS. The macOS jobs run `make check`, and there is no `dpkg` there,
so no macOS job exercises the chain any more. Nothing about the chain is
platform-specific except how it is installed, and every component is still
covered on macOS by its own tests; what macOS stops proving is that the parts
compose. Verifying that on macOS needs the chain installed the way macOS
installs it, which is a separate decision and is not taken here.
