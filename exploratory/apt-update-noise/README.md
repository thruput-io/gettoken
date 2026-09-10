# Is `Read error - read (21: Is a directory)` a failure the verification walked past?

Every verification run printed this three times per `apt-get update`, against our
own archive:

```
Err:3 file:/work/build/packages/deb-testing ./ Packages
  Read error - read (21: Is a directory)
W: Symlinking file  to .../Packages.xz failed - pkgAcqIndex::StageDownloadDone
```

It reads like the index could not be read, and the run continued anyway. `ask.sh`
asks whether `set -e` was walking past a real failure.

Run it against a built archive on the official image for a release:

```sh
docker run --rm -v "$PWD":/work -w /work debian:testing-slim \
  bash exploratory/apt-update-noise/ask.sh /work/build/packages/deb-testing
```

## What it answers

`apt-get update` exits 0 with those six lines on the shelf, so nothing was being
walked past: it is not reporting a failure it then swallowed.

They are apt probing. The archive carried no `Release` file, so both `InRelease`
and `Release` are `Ign` and apt has to guess which compressions of `Packages`
exist. It asks for `Packages.xz`, `Packages.bz2` and `Packages.lzma`, none of
which we write, and its `file:` method reports each miss by reading the directory
the name resolves in. It then reads `Packages.gz` and is correct.

Fail-fast is intact underneath. Corrupt the index and `apt-get update` exits 100;
point the source at a directory that is not there and it exits 100. Both abort
under `set -e`. `-o APT::Update::Error-Mode=any` changes neither, measured: apt
already treats both as errors.

The defect is that the line a failing source prints — `Err:3 ... ./ Packages` —
is the same line the probing prints. Nothing reading the log can tell them apart,
so six false alarms per run devalue the real one.

## What this means for the verification

Writing a `Release` file beside the index with `apt-ftparchive release .` tells
apt exactly which index files exist. The probing stops: six error lines and three
warnings become zero, and the chain still resolves to all 22 packages.

That makes the log unambiguous, which is what lets the run assert on it.
`scripts/archive.sh` now refuses any `Err`, any `Read error`, and any `W:` naming
the archive, so what used to be noise stops the run instead. Removing the
`Release` file again is caught by that check rather than printed and passed over.
