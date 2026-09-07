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

Per tool means one, not two. Record 7 shows `gh-gettoken` beside `gh` because
`gh` is upstream's package and not ours to change. A tool we ship ourselves has
no such package to stand beside, so the tool and its exchanger go together.

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

`gettoken-contract` depends on the validator, which is the reason record 16
replaced the one record 13 had chosen: a package can only declare what the
archive carries.

## Verification

`make debian-packages` builds the packages inside a base that carries the tools
to build them and nothing they run on, has `lintian` read them, installs them
with `apt`, and runs the chain against what was installed rather than against the
checkout: the store is the real one, the capability is listed, `gettoken` is
invoked by name from a default `PATH`, and the tool runs on what comes back. It
then purges every package and fails if anything is left behind.

The base is bare on purpose, and one package is installed, not seven. A rig that
installs what the packages need — or names them all itself — is a rig in which
`Depends` is decorative: nothing would fail if a package forgot to declare
something, because it would already be there. So the packages are served to `apt`
as an archive it resolves by name, the run asserts the absence first, and asserts
afterwards that everything else arrived marked as drawn in rather than asked for
— and that purging the one package takes all of it away again.
