# 31. Distribution lives in the apt and brew repositories

## Context

A user installs gettoken with apt or brew, from one archive and one tap that
serve everything thruput-io ships.

## Decision

gettoken builds packages and releases them. It does not sign or serve them.
