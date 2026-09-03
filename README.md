# gettoken

A text-based, POSIX-native token broker for AI agents.

An agent is a user, not a new kind of system. Identity, isolation, and authority
are the OS user model, privilege separation, and a package manager — reused, not
reinvented. The wire is stdin/stdout and exit codes. The request/response
contract is OAuth2 token exchange (RFC 8693) with a JWT client assertion
(RFC 7523), so the eventual off-the-shelf STS drops into place speaking its
native shape.

## Principles

- **Working end-to-end is an invariant, not a goal.** Every commit keeps the
  chain running (`test/walk.sh` stays green).
- **Completeness and depth are independent.** Every component exists as a stub
  that honors its contract; the system is always complete, and depth is added to
  one component at a time, on demand.
- **Contracts are fixed; implementations are disposable.** The schemas in
  `contracts/` are the sacred part. A stub behind a stable contract can be
  replaced with the real thing invisibly to its neighbours.
- **Reuse human-refined technology.** POSIX, apt, `gh`, an OAuth2 STS. Adopt the
  vocabulary and semantics, never the transport you would not use yourself.

## Components

Fixed faces (name + concern). The implementation of each evolves top-to-bottom;
the first incarnation is what ships in this repo.

| # | Component | Concern | First incarnation → future |
|---|-----------|---------|----------------------------|
| 1 | `gettoken` | agent's entry point; `--list` and `<scope>` | forwarder (stable) |
| 2 | `token-requester` | privileged half; builds the signed exchange request | local root/dev → gh app signing → orchestrator/container id |
| 3 | `token-service` | authenticate, resolve, exchange | transitive trust, as-is → validate assertion → off-the-shelf OAuth2 STS |
| 4 | `notifier` | summon a human to renew | beep + shell → 2FA/phone → mostly automated |
| 5 | `auth-canvas` | surface the human acts on | prepped shell (`gh auth login`) → mobile/web |
| 6 | `secret-manager` | holds super-tokens on the privileged side, keyed by (agent, location, scope) | privileged folder → secrets manager |
| 7 | `entitlements` | what an agent may equip | script entry → operator-managed |
| 8 | `agent-identity-authority` | proves who the agent is | local OS user → gh app signed → GCP service principal |

Components 4–8 are named seats. This walking skeleton implements the request
path (1 → 2 → 3, with 6 and 7 as stubs). The notifier, auth-canvas, and
identity authority are the next seats to fill, on demand.

## Contracts

- `contracts/request.schema.json` — RFC 8693 token-exchange request.
- `contracts/response.schema.json` — token-exchange response.
- `contracts/defs.schema.json` — every domain object defined once; the request
  and response only `$ref` these, never inline a constraint.

Deliberate deviation from vanilla token-exchange: the agent must never hold the
super-token, so `subject_token` is **not** in the request. token-service fetches
it server-side from the secret-manager, keyed on the client_assertion's claims +
scope. Agent identity and location are claims **inside** `client_assertion`, not
top-level request fields.

## Run the walking skeleton

```sh
sh test/walk.sh
```

It lists the one known scope, requests it, and checks a token-exchange response
comes back. This is the invariant: keep it green.

## Layout

```
bin/         the executables (gettoken, token-requester, token-service, entitlements, sign)
contracts/   the fixed schemas — the sacred part
test/        the end-to-end walk
```
