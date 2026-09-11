# 22. The archive is published, one suite per branch

## Context

Packages that exist only where they were built can only be installed there.

## Decision

Every branch publishes what it built as a signed apt archive, under a suite named after the branch, and `main`'s suite is the release. What verifies the packages installs them from that archive rather than from a directory of files.

The archive occupies `/apt` on the site, not its root.

## Motivation

A snapshot anyone can install is what makes a branch reviewable before it is merged, and promoting one is then merging it rather than moving files about. Signing is what lets an archive be reached from anywhere: one that apt is told to trust without checking is only ever safe on the machine that built it.

A published URL cannot be moved once anyone has installed from it, and the site serves one project rather than one package format. Naming the corner the archive occupies leaves the rest of the site free for what macOS is distributed by.
