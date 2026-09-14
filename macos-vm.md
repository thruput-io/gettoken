# Ephemeral macOS 26 box alongside Colima

Status: plan. Nothing here is installed, and no instance has been created.

## 1. Goal

A macOS 26 box that can be torn down and restored to a known starting state, run
headless, with the smallest reasonable footprint. The shared Docker environment
must be left untouched.

Ephemeral is the requirement. Isolation is a consequence of the design, not a goal
in itself.

## 2. Why the box sits beside Colima and not inside it

A macOS guest cannot run inside the Colima VM.

* Nested virtualization exposes `/dev/kvm` in the Linux guest. KVM on aarch64 has
  no implementation of Apple's signed IPSW boot chain
  (`VZMacOSRestoreImage` / `VZMacPlatformConfiguration`).
* QEMU's `vmapple` machine is the closest thing that exists and supports only
  macOS 12.x.
* The *macOS on Incus* guide is built on OpenCore and is explicitly x86-only:
  "While this guide provides no support for non-Intel processors, contributions
  for AMD processors are welcome." It also builds macOS 15.6.

What nested virtualization buys is therefore **Linux** VMs in Incus — Kata,
KubeVirt, Firecracker. macOS is outside what the flag can reach on this hardware.

The box is therefore a sibling of the Colima VM, directly on
`Virtualization.framework`.

## 3. Foundation

The instances live under the service account **`_colima`**. The account exists, has
a working home, and Colima already proves that `vz` runs headless there.

Lima uses `~/.lima`. Colima uses `~/.colima/_lima`. They do not collide, and no new
account setup is needed.

The pattern follows `colima-shared`: a versioned template under `/usr/local/etc`,
argument-less wrappers under `/usr/local/libexec`, a dispatcher on PATH, and
`sudoers` for `%developers`.

### Two instances

| Instance | Role | State |
|---|---|---|
| `macos-snapshot` | the starting state, built once from the template | always **stopped**, `limactl protect` |
| `macos` | the throwaway box, cloned from the snapshot | started, used, destroyed |

The name `macos-snapshot` describes the role. It is **not** a Lima snapshot:
`limactl snapshot` is unimplemented under `vz` (see section 8).

### A note on naming

Three naming families appear, and they are kept apart on purpose:

* **`macos-vm`** — the command and its wrappers: `/usr/local/bin/macos-vm`,
  `/usr/local/libexec/macos-vm-*`, `/etc/sudoers.d/61-macos-vm`.
* **`macos-26`** — the platform: the template file
  `/usr/local/etc/lima/macos-26.yaml` and Lima's `template:_images/macos-26`,
  matching the repository's existing `Makefile.macos-26`.
* **`macos` and `macos-snapshot`** — the Lima instance names, seen only through
  `limactl`.

Nothing collides, and knowing which family a name belongs to tells you what any
given string refers to.

## 4. The template — `/usr/local/etc/lima/macos-26.yaml`

```yaml
minimumLimaVersion: 2.3.0-beta.0

base:
- template:_images/macos-26          # IPSW 26.5.2, aarch64, os: Darwin, vmType: vz

cpus: 2
memory: "4GiB"
disk: "64GiB"

vmOpts:
  vz:
    diskImageFormat: "asif"          # sparse; requires a macOS 26 host

video:
  display: "none"                    # the base template sets "default" — this overrides it

osOpts:
  Darwin:
    suppressFirstLoginSetup: true    # without this the guest stops in Setup Assistant

mounts:
- location: "/Users/Shared/workspace"
  writable: true

ssh:
  loadDotSSHPubKeys: false
```

The template deliberately bases only on `_images/macos-26`, not on
`template:macos`. The latter pulls in `_default/mounts`, which mounts `~` — here
`_colima`'s home, which has no business inside the guest.

If "smallest footprint" means least disk used, `asif` is the answer, not a small
`disk:` number: the format is sparse, so 64 GiB logical costs only what is actually
written. A number set too low merely makes the IPSW restore fail halfway.

## 5. The scripts

Every wrapper under `/usr/local/libexec` shares the same preamble. `cd /` is
required because `sudo` preserves the caller's working directory, which `_colima`
cannot traverse — without it you get
`getcwd: cannot access parent directories: Permission denied`.

```sh
#!/bin/sh
set -eu
cd /
golden=macos-snapshot
instance=macos
template=/usr/local/etc/lima/macos-26.yaml
owner=_colima

if [ "$(id -un)" != "$owner" ]; then
  echo "${0##*/}: must run as $owner" >&2
  exit 1
fi

HOME=/Users/$owner
PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
LIMA_HOME=$HOME/.lima
export HOME PATH LIMA_HOME
```

### `macos-vm-build` — the one-time job

Argument check `[ $# -ne 0 ] && exit 1`, then:

```sh
security unlock-keychain -p '' "$HOME/Library/Keychains/login.keychain-db"

limactl unprotect "$golden" 2>/dev/null || true
limactl delete -f "$golden" 2>/dev/null || true
limactl start --tty=false --name="$golden" "$template"
limactl stop "$golden"
limactl protect "$golden"
```

This is the expensive operation: a full IPSW restore. It runs once. `protect` is
what stops `delete` or `factory-reset` from taking the starting state by accident.

### `macos-vm-reset` — the throwaway loop

Argument check, then:

```sh
limactl delete -f "$instance" 2>/dev/null || true
limactl clone "$golden" "$instance"
exec limactl start --tty=false "$instance"
```

### `macos-vm-destroy`

```sh
exec limactl delete -f "$instance"
```

### `macos-vm-shell` (takes arguments) and `macos-vm-status` (takes none)

```sh
exec limactl shell "$instance" -- "$@"
exec limactl list "$instance"
```

### Dispatcher — `/usr/local/bin/macos-vm`

```sh
#!/bin/sh
set -eu
cd /
owner=_colima
libexec=/usr/local/libexec
usage() { echo "usage: macos-vm build|reset|shell|destroy|status" >&2; exit 1; }
[ $# -ge 1 ] || usage
verb=$1; shift
case "$verb" in
  build|reset|destroy|status)
    [ $# -eq 0 ] || usage
    exec sudo -u "$owner" "$libexec/macos-vm-$verb" ;;
  shell)
    exec sudo -u "$owner" "$libexec/macos-vm-shell" "$@" ;;
  *) usage ;;
esac
```

## 6. `/etc/sudoers.d/61-macos-vm`

```
%developers ALL=(_colima) NOPASSWD: /usr/local/libexec/macos-vm-build ""
%developers ALL=(_colima) NOPASSWD: /usr/local/libexec/macos-vm-reset ""
%developers ALL=(_colima) NOPASSWD: /usr/local/libexec/macos-vm-destroy ""
%developers ALL=(_colima) NOPASSWD: /usr/local/libexec/macos-vm-status ""
%developers ALL=(_colima) NOPASSWD: /usr/local/libexec/macos-vm-shell
```

`""` means zero arguments permitted. The last line omits it deliberately — `shell`
must accept arguments.

The lines must start with `%`. Without it, sudoers looks for a *user* named
`developers`, which fails silently and leaves nothing working.

No generic binary — not `env`, not `limactl` — is granted through sudo. `LIMA_HOME`
is set inside the wrapper. Otherwise the rule would be a path to running anything
as the account that owns the shared Docker.

## 7. Installation

```sh
sudo install -d -m 755 /usr/local/etc/lima
sudo install -m 644 macos-26.yaml    /usr/local/etc/lima/macos-26.yaml
sudo install -m 755 macos-vm-build   /usr/local/libexec/macos-vm-build
sudo install -m 755 macos-vm-reset   /usr/local/libexec/macos-vm-reset
sudo install -m 755 macos-vm-destroy /usr/local/libexec/macos-vm-destroy
sudo install -m 755 macos-vm-shell   /usr/local/libexec/macos-vm-shell
sudo install -m 755 macos-vm-status  /usr/local/libexec/macos-vm-status
sudo install -m 755 macos-vm         /usr/local/bin/macos-vm
sudo install -m 440 61-macos-vm      /etc/sudoers.d/61-macos-vm
sudo visudo -c
```

## 8. Fastest way to reset

Four paths were considered. Three fail.

| Path | Evidence | Cost |
|---|---|---|
| `delete` + `start` | full IPSW restore again | tens of minutes |
| `snapshot apply` | `CreateSnapshot`, `ApplySnapshot`, `DeleteSnapshot` and `ListSnapshots` all return `errUnimplemented` in `pkg/driver/vz/vz_driver_darwin.go` | does not exist |
| `factory-reset` | `cmd/limactl/factory-reset.go` retains only `lima-version`, `protected`, `vz-identifier` and `*.yaml` — the disk image is deleted | as expensive as `delete` + `start` |
| `delete` + `clone` | `pkg/instance/clone.go`: `// CopyFile attempts copy-on-write when supported by the filesystem` → `unix.Clonefile` on Darwin, and the disk is APFS | near zero |

Cloning costs neither time nor disk space, because APFS writes only the blocks that
actually change. Hence `macos-vm reset`.

The source requires `macos-snapshot` to be stopped: `cannot clone a running
instance`. That suits the design — the starting state is never started again after
the build.

## 9. Verification gates

### Gate 0 — prerequisites, before anything else

| Check | Command | Requirement | Status |
|---|---|---|---|
| Lima version | `limactl --version` | >= 2.3.0-beta.0 | OK: `2.3.0-beta.0-57-g3148fe7f` |
| Host CPU | `sysctl -n machdep.cpu.brand_string` | Apple silicon | OK: M5 |
| Host OS | `sw_vers -productVersion` | >= 26 for `asif` | OK: 26.6.2 |
| Disk space | `df -h /` | >= 100 Gi free | OK: 727 Gi |

### Gate 1 — the template, before installing or downloading anything

The cheapest gate. `base:` merging can silently eat your own overrides, especially
`video.display`, which the base template sets to `"default"`.

```sh
limactl validate macos-26.yaml
limactl template copy --fill macos-26.yaml - > resolved.yaml
```

Result (already run):

```
`macos-26.yaml`: OK                          rc=0

vmType: vz            os: Darwin             arch: aarch64
cpus: 2               memory: 4GiB           disk: 64GiB
osOpts.Darwin.suppressFirstLoginSetup: true  <- survives the merge
video.display: none                          <- beats the base template's "default"
vmOpts.vz.diskImageFormat: asif
mounts: [ /Users/Shared/workspace ]           <- only this one, no ~
images: UniversalMac_26.5.2_25F84_Restore.ipsw
```

Two things are thereby established without a single download: the schema accepts
`suppressFirstLoginSetup`, and basing on `_images/macos-26` did in fact produce only
the intended mount.

**Abort criterion:** if any field above is missing, the template is wrong. Do not
continue.

### Gate 2 — the scripts, before installation

```sh
for f in macos-vm macos-vm-build macos-vm-reset \
         macos-vm-destroy macos-vm-shell macos-vm-status; do
  sh -n "$f" && shellcheck -s sh "$f"
done
```

`sh -n` is not enough. A script that executes the wrong command is syntactically
clean — that was exactly the fault in `colima-shared-stop`, which was a copy of the
start script and ended in `colima start`. So behaviour tests too:

```sh
./macos-vm-reset extra    # expected: rc=1, "takes no arguments"
./macos-vm-reset          # expected: rc=1, "must run as _colima"
```

Both must fail. If they do not, the guard has no effect.

### Gate 3 — sudoers, before and after

```sh
visudo -c -f 61-macos-vm                 # standalone, before install
sudo install -m 440 61-macos-vm /etc/sudoers.d/61-macos-vm
visudo -c                                 # the whole tree
sudo -l -U <user> | grep macos-vm         # show exactly what was granted
```

The negative test is the only thing that proves the argument restriction bites:

```sh
sudo -u _colima /usr/local/libexec/macos-vm-reset extra
```

It must be refused by **sudo**, not by the script. If you see the script's own error
message, the `""` restriction has no effect.

### Gate 4 — the build

```sh
time macos-vm build
limactl list macos-snapshot      # expected: Stopped
limactl delete macos-snapshot    # expected: refused, "instance is protected"
```

That the command **returns at all** is the proof that Setup Assistant is suppressed.
Without `suppressFirstLoginSetup` the build hangs waiting for clicks in a GUI window.

### Gate 5 — the throwaway loop

```sh
df -h / | awk 'NR==2{print $4}'           # free before
time macos-vm reset
df -h / | awk 'NR==2{print $4}'           # free after
du -sh ~_colima/.lima/macos/*.asif        # allocated
ls -lh ~_colima/.lima/macos/*.asif        # logical
```

If free space drops by tens of GiB it is not a copy-on-write clone, and the whole
premise for "fast" is wrong. `du` must show far less than `ls`.

That the box is genuinely fresh:

```sh
macos-vm shell -- touch /tmp/keep-me
macos-vm reset
macos-vm shell -- ls /tmp/keep-me         # expected: No such file
```

That the guest is the intended one:

```sh
macos-vm shell -- sw_vers                 # expected: ProductVersion 26.5.2
macos-vm shell -- uname -m                # expected: arm64
macos-vm shell -- ls /Users/Shared/workspace
```

### Gate 6 — regression against shared Docker

```sh
docker info >/dev/null && echo 'docker untouched'
colima-shared status
```

## 10. Open items — things without evidence

**The keychain.** From macOS 15 onward `Virtualization.framework` requires an
unlocked `login.keychain`, and that is normally only unlocked in GUI sessions.
`security unlock-keychain -p ''` in the wrapper is an **assumption** about how
`_colima` gets around it. That Colima works today shows it is possible, not that it
works that way. This is the most likely place to get stuck. The failure signature to
look for is verbatim `Interaction is not allowed with the Security Server`.

**Headless.** The Lima documentation lists "no video display toggle" among the
features not yet finished for macOS guests. `display: "none"` is set because the base
template otherwise sets `"default"`, but if `vz` opens a window anyway that is a fault
to be seen, not worked around. Check during Gate 4, from another shell:

```sh
pgrep -lf 'limactl.*macos'
limactl screenshot macos-snapshot    # should fail when display is none
```

**`vz-identifier`.** The machine identity lives in the instance directory and is
carried into the clone. Two instances sharing an identity does not matter as long as
only one runs, which is the case here because `macos-snapshot` is always stopped.
Running both at once is uncharted territory.

**Password-less sudo in the guest.** Lima disables it for macOS guests except for
`/sbin/shutdown -h now`. `Makefile.macos-26` only runs `brew install`, which does not
need sudo, but anything else that wants it will fail.

**Port forwarding.** Lima has no automatic port forwarding for macOS guests.
`limactl shell` goes over SSH and is enough to run make targets; if ports are needed
it takes `ssh -L` or `vzNAT`.

## 11. Sources

* macOS guests in Lima: <https://lima-vm.io/docs/usage/guests/macos/>
* Lima v2.1, macOS guests: <https://www.cncf.io/blog/2026/03/25/lima-v2-1-macos-guests-and-enhanced-ai-agent-safety/>
* Lima releases: <https://github.com/lima-vm/lima/releases>
* macOS on Incus (x86-only): <https://discuss.linuxcontainers.org/t/macos-on-incus-guide/25244>
