# 22. An integration test is the use-case a person types

## Context

One run asserted the packaging, the archive, the chain and the purge, and what it covered could not be read off it. It ran in the base that built the packages, which already carries most of what a package brings. The directory named for integration tests held the unit tests.

## Decision

An integration test is a use-case, and a use-case is what a person types. It runs on an official image with nothing installed onto it first.

## Motivation

A base already holding the chain cannot show that installing one package brought it. A safeguard belongs on the leftmost rung that can catch it, and an installed system is the rightmost there is, so most of what the run asserted moves to the tests of the component that owns it. Two checks are dropped rather than moved, and this record permits that reduction. What is no longer caught is a component depending on more than it speaks.
