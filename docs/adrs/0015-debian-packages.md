# 15. Debian packages

## Context

Record 7 decided distribution is apt and that a tool is integrated by publishing a package. It did not say what is packaged, or where a package puts what it carries. Until that is settled there is nothing to install.

## Decision

One source package, and one binary package per component and per tool. The agent's entry point is the only public name.

## Motivation

A component is replaceable one piece at a time, and a package is the unit that gets replaced. One source tree already yields many binary packages, so splitting the source would put a release process between components edited in one commit. A tool we ship has no upstream package to stand beside, so it carries its own exchanger. An agent must not be able to shadow what runs on the privileged side by placing a file earlier on the path. A store is state, and purging what owns it takes it away.
