# 20. The chain is verified against installed packages

## Context

The run that exercised the chain put directories of a checkout on the path and reached components by names no installed system offers. It was the run the suite executed. Most of what it asserted was one component's behaviour.

## Decision

The chain is exercised in one place, against installed packages. What was asserted of a single component moves to that component's own tests.

## Motivation

A run that drives a checkout through entry points nothing ships proves the checkout works, not the product. Installing one package and letting apt draw in the rest exercises the chain a machine would have. Asserting one component's behaviour needs a stand-in for its collaborator, which is a unit test and belongs beside it. The suite no longer exercises the chain end to end, and this record permits that reduction.
