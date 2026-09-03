# 4. Signing a request

## Context

Something has to vouch for a request being what it says it is.

## Decision

`signed` names what vouched for the request.

`host-privileged` means the request was produced on the privileged side of this
host. That is accepted here, because it is true here. Nothing off this host
accepts it, because nothing off this host can know it.

The key that signs a request is one-to-one with the first segment of `doing`.

The deployment is where that key is put.
