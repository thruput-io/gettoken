# 26. On macOS privileged is the installing account

## Decision

On macOS, privileged is the user that has `brew` — what "current user" is when
the privileged components are installed.

Unprivileged on macOS is someone that is prevented from calling `su` or `sudo`.
