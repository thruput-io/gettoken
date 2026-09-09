# 21. A contract is a package

## Context

This is the Bridge Pattern, by Separated Interfaces. 

## Decision

Each contract is its own package, and a component depends on the contracts it speaks, never on other components directly. 

## Motivation

The package manager can handle compatibility between components and their future variants. That is what it is built for.
A package capability can be derived from to pairs of contracts it depends on, discovery delivered by the package manager.

