# 6. Exchangers

## Context

Turning a super-token into a narrow one is specific to the service it belongs
to. What GitHub wants asked, and how, is not what another service wants asked.

## Decision

`token-service` dispatches on the first segment of the capability. The exchanger
registered for that segment performs the exchange.

The exchanger translates the capability into whatever that service actually
wants. For GitHub that is a set of permissions on the repository named in the
capability, not GitHub's own coarse scopes. The logic is the same every time;
the repository is what varies.

An exchanger issues a token that lives as short a time as possible, ideally two
minutes.

Exchangers ship in the package of the tool they serve, and are found where that
package puts them.
