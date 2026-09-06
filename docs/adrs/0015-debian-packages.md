# 15. Debian packages

## Context

Record 7 decided that distribution is `apt` and that a tool is integrated by
publishing a package. It did not say what is packaged, or where the packages put
what they carry. Until that is settled there is nothing to install, and the
chain can only be run from a checkout.

## Decision

One source package, and one binary package per component and per tool.

A component is replaceable one piece at a time, and a package is the unit that
gets replaced. Splitting the source as well would put a release process between
components that are edited in one commit and verified in one run, for no gain:
Debian's source format already produces many binary packages from one tree.

`/usr/bin` carries the agent's entry point and nothing else. The rest goes to
`/usr/lib/gettoken`, which `gettoken` puts on `PATH` before it crosses into the
privileged half. Names like `validate`, `entitlements` and `token-service` are
not ours to claim on a public `PATH`, and an agent must not be able to shadow
what runs on the privileged side by placing a file of its own earlier on `PATH`.

The contracts are installed data, at `/usr/share/gettoken/contracts`.
`token-service` reads exchangers out of `/usr/lib/gettoken/exchangers` by the
first segment of the capability, which is the directory record 7 named. It no
longer searches `PATH` for them: what runs there is run with the super-token in
reach, so where it comes from is fixed by the filesystem rather than by whatever
`PATH` happened to hold.

The super-token store moves from `/secret` to `/var/lib/gettoken/secrets`. A
package may not own a directory at the root of the filesystem, and a store is
state, which is what `/var/lib` is for. Purging the package that owns it takes
the store with it, because a super-token left behind on a machine that no longer
runs any of this is the failure the whole design exists to avoid.

The validator named in record 13 is not distributed as a Debian package, so
`gettoken-contract` cannot declare a dependency on it and `apt` cannot install
it. It has to be on the host already. This is stated so it is read as a known
gap rather than an oversight.

## Verification

`make debian-packages` builds the packages inside a named base, has `lintian`
read them, installs them with `apt`, and runs the chain against what was
installed rather than against the checkout: the store is the real one, the
capability is listed, `gettoken` is invoked by name from a default `PATH`, and
the tool runs on what comes back. It then purges every package and fails if
anything is left behind.
