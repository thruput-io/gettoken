# 8. Credential helpers

## Context

Some toolsoffera credential helper hook.

## Decision

We encourage using get-token as a credential-helper. That is the tool's own extension point.
Installing get-token as a credential-helper is the responsibility of this project’s users.
We do not pre-install get-token as a credential-helper in our packages.

## Motivation

We have exactly one token interface with the agent; the agent's entry point, being transparent and explicit about it is future-proof and compliant with this project's principles. 
Pre-installation of credential-helper can be perceived as magic, hide exchanger variables, create confusion and ultimately increasing the risk of unintended misuse.
