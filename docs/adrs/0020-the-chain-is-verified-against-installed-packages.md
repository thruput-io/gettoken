# 20. The chain is verified against installed packages

## Context

This repository is about packaging and permissions.

## Decision

Integration tests run on a pristine official image, setup uses the package manager alone, and dependencies are installed in the test file itself.

## Motivation

A run that drives a checkout through entry points nothing ships proves the checkout works, not the product. Installing one package and letting the package manager draw in the rest exercises the chain a machine would have.
