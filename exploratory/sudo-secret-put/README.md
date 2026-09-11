# Can the human's step in the use-case be `sudo secret-put`?

Record 11 and issue 34 both name a sudo rule as the door the agent crosses. The
use-case in `integration-test/test.sh` has a step where the human puts the
super-token in the store, and writing it as `sudo secret-put < document` would
say that out loud. `ask.sh` asks whether it can be written that way today.

Run it against the published archive on the official image for a release:

```sh
docker run --rm -v "$PWD":/work -w /work debian:testing-slim \
  sh exploratory/sudo-secret-put/ask.sh \
  https://thruput-io.github.io/gettoken main/deb-testing testing-slim
```

## What it answers

`sudo` is not on the official image, and installing it draws in four packages.

`sudo /usr/lib/gettoken/secret-put` then exits 127 with
`/usr/lib/gettoken/secret-put: 6: parse: not found`. Sudo resets the
environment, and `secret-put` reaches for `parse` and `format` on `PATH`. It
runs only when the path is carried across explicitly, as
`sudo PATH=/usr/lib/gettoken:/usr/bin:/bin /usr/lib/gettoken/secret-put`, which
is a sudoers rule's job rather than a caller's.

`sudo id -un` and `id -un` both answer `root`. There is no boundary for sudo to
cross, so the word would assert a separation that is not there. That is issue
34, measured rather than argued.

## What this means for the use-case

The step stays as a document fed to `secret-put` on standard input, which is the
shape a sudo rule would take, without the word that would make it a claim. When
issue 34 settles how the agent crosses over, this experiment says what the
sudoers rule has to carry for `secret-put` to work behind it.
