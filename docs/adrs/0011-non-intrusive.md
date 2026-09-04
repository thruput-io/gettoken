# 11. Non-intrusive

## Context

We package tools that people already use. Whoever installs one of our packages
was using `az` or `gh` before, by hand, with no agent involved, and will carry on
doing so afterwards.

## Decision

A tool package does not change the tool.

Installing one leaves the tool's default behaviour exactly as it was. No
configuration is rewritten, no default is altered, no credential is left behind,
and nothing is added to a shell profile.

Whatever the package installs is additional, and inert until something asks for
it. Someone who installed a tool package and then forgot about it should not be
able to tell.

Removing the package leaves nothing behind.
