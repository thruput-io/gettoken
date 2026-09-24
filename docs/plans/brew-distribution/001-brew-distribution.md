# 001 — Brew distribution

|                |                                                            |
|----------------|------------------------------------------------------------|
| Plan           | `docs/plans/brew-distribution/001-brew-distribution.md`    |
| Branch         | `tore/001-brew-distribution`                                |
| Started        | 2026-09-24                                                  |
| Supersedes     | —                                                            |
| ADRs consulted | 27, 29, 26, 25, 24, 23, 22, 21, 17, 8, 7                     |
| ADRs added     | —                                                            |
| Status         | draft                                                        |

## Implementing Agent Instructions

Read this section first, and in full, before touching any code.

**Read before starting.**
[`RULES.md`](https://github.com/thruput-io/handbook/blob/main/RULES.md),
[`PHILOSOPHY.md`](https://github.com/thruput-io/handbook/blob/main/PHILOSOPHY.md),
[`WORKFLOW.md`](https://github.com/thruput-io/handbook/blob/main/WORKFLOW.md), and this plan end
to end. They outrank this plan; raise any conflict with the human instead of resolving it
yourself. Also read ADR 27 and ADR 29 — they govern how `PACKAGE_FORMATS` and `constants.env`
decide what a platform builds, which this plan works inside rather than around.

**Scope.** Implement exactly the milestones in [Execution Plan](#execution-plan), in order.
Anything not in this plan is out of scope — stop and ask rather than extending it.

**Definition of done.** Implementation is complete when every milestone's verification test
passes, `make unit lint` reports success, the black-box flow (`source dynamic.sh; bash
src/integration-test/test.sh` — never `make test`, see [D7](#discussions)) succeeds on a
genuinely clean Darwin image with `PACKAGE_FORMATS=brew`, and every goal in [Goals](#goals) is
delivered per the [Goal coverage](#goal-coverage) table.

**Verification.** Run `make unit lint` for the quality gates (a build machine with a toolchain,
unchanged by this plan). For the black-box proof, run `dynamic.sh` then `test.sh` directly on a
machine that has installed nothing but what those two scripts install themselves — `make test`
requires `make` and the whole Makefile graph before anything runs, which is not the clean machine
a real installer sees ([D7](#discussions)). Do not treat a milestone as done on inspection alone;
on macOS, run it in a pristine `macos-vm` guest or in CI, never on a developer's own Homebrew
prefix.

**Related, out of scope.** `verifications.yml`'s existing Debian `integration` job runs `make
test` (merged in PR #50) and has the same problem D7 describes — it installs `make`/`git` before
anything, which a real apt install never needs. Fixing it is not one of this plan's goals; flag it
to the human rather than fold it in silently.

### Progress log

Keep an append-only progress log for this attempt:

- Open `docs/plans/brew-distribution/progress/001-attempt-1-{YYYY-MM-DD}.md` before the first
  change, where `{n}` is one higher than the highest attempt already in `progress/`.
- Append as you go: what you attempted, what the evidence showed, what you decided, what broke.
- **MUST NOT** rewrite, condense, or delete an existing entry. Corrections are new entries.
- **MUST NOT** amend or force-push a commit that contains progress-log entries.
- Commit the log alongside the work it describes.

**If this attempt is abandoned:** open a pull request carrying the progress log, and state in
the PR body what was attempted, where it broke, and what the next attempt should do
differently. Do not delete the branch or the log — the record of the failure is the deliverable.

## Background

`docs/adrs/0027-platform-by-makefile.md` requires the Makefile to produce a Homebrew formula,
built from source, no bottle, as a hard-coded outcome of the build on every platform (narrowed by
ADR 29's `PACKAGE_FORMATS`: only the format(s) a platform's `constants.env` entry names actually
build there — today that is `brew` on Darwin, `deb` on Debian).

That requirement has never been met. `scripts/deliver-brew.sh` writes a placeholder formula whose
`sha256` is thirty-two zero bytes and whose `url` points at a git tag that does not exist — no tag
exists in this repository at all. This is not new: an earlier `scripts/publish-brew.sh`, deleted
in commit `f36cce5`, was a nine-line stub whose entire body was
`echo "TODO: publishing $formula to a tap is not implemented" >&2; exit 1`. It was briefly
replaced by `scripts/publish-brew-to-container.sh`, which copied formulae into a local nginx
container — not a channel any real `brew install` could reach — and that too was removed. No
`homebrew-*` or tap-named repository exists in the `thruput-io` GitHub organization today. Every
attempt at brew distribution in this repository's history has stopped at the same point: a
formula with nowhere real to install from.

Meanwhile the apt side is fully real: a signed archive, published per branch, installed and
exercised black-box in CI (`docs/adrs/0022`, `docs/adrs/0020`). This plan brings brew to the same
state: a tap a user can actually `brew tap` and `brew install` from, proven by the same kind of
black-box test the Debian side already has, with `macOS stable` (currently a checkout-only
placeholder, tracked in issue #51) exercising it for real.

### Goals

1. `brew install` from a published tap installs a working `gettoken`, built from source, that
   behaves identically to the apt-installed one for an agent asking for a capability.
2. The published tap is proven by an automated black-box test — the same class of proof
   `docs/adrs/0020` requires for apt — not by inspecting that `brew install` exited zero.
3. CI's `macOS stable` job exercises that real install-and-use flow instead of only checking out
   the repository (closes issue #51).

#### Cheapest passing interpretation

| Goal | Cheapest way to "pass" while missing the point | How the goal excludes it | Accepted by |
|---|---|---|---|
| 1 | A single formula with a real `url`/`sha256` whose `def install` only symlinks `bin/gettoken`, without building or installing the privileged-half scripts (`token-requester`, `secret-manager`, `token-service`, `entitlements`, the exchanger) as their own installable units — `brew install` succeeds, `gettoken` fails at first real use, and the tap does not mirror apt's package boundaries. A weaker cheat: 22 formulae exist, but with no real `depends_on` between them (dependency edges only in a comment, or every formula standing alone) — the count is right and the wiring, which is what makes the mirror real rather than cosmetic ([D6](#discussions)), is missing. | "Behaves identically... for an agent asking for a capability" requires the full request path to work; [D2](#discussions)/[D6](#discussions) require the tap to mirror apt's boundaries *and* its dependency graph, not just its package count. | pending |
| 2 | A bats test that asserts `brew install gettoken` exits 0 and stops there. | "Proven... by the same kind of black-box test ADR 0020 requires" ties the bar to the existing Debian integration test's shape: install via the package manager alone, then exercise the product through its public interface. | pending |
| 3 | Rename the job or add a step that runs without asserting anything — this is the exact pattern PR #50's review caught in the previous `macOS stable` job. | "Exercises that real install-and-use flow" is the same flow goal 2 proves; a job that does not run it does not satisfy this goal regardless of its name or green status. | pending |

### Non-goals

- Homebrew bottles (pre-built binaries). ADR 27 restricts brew to a source-built formula; revising
  that is a separate decision, not part of this plan.
- Changing anything about the apt archive, its signing, or its publishing.
- Per-component version numbers. Versioning is repo-wide for now ([D3](#discussions)).

## Summary

`version.txt` holds `MAJOR.MINOR`; CI appends the build number as the patch digit and cuts a git
tag on every merge to `main` ([D3](#discussions), [D4](#discussions)). A generator script, run
from the same contract/component data `scripts/packaging.sh` already reads to build `debian/control`,
emits one Homebrew formula per apt package — including the ten contract-only ones — each building
from that tag's source tarball and wired together with `depends_on` the way apt wires them with
`Depends` ([D2](#discussions), [D6](#discussions)). `thruput-io/homebrew-tap` ([D1](#discussions))
receives them via the same installation-token push `pages_push` already uses for the apt archive
([D5](#discussions)). `macOS stable` in CI (currently a placeholder, issue #51) installs from that
tap and runs the same class of black-box, capability-exchange assertion the Debian integration job
runs.

## Assumptions, risks and preconditions

| Assumption or risk | How it was tested | Result | If it turns out false |
|---|---|---|---|
| The GitHub App installation can be granted write access to a new `thruput-io/homebrew-tap` repo | Not tested — `gh api orgs/thruput-io/repos` confirms the repo does not exist yet ([D1](#discussions)) | untested | M3 creates the repo and grants access before attempting the push; if refused, escalate to the human rather than work around it |
| The vendored Go contract component needs no network to build | Read ADR 24 (`-mod=vendor`, no `buildvcs`) | confirmed by the ADR's own reasoning, not independently re-run in this plan | brew's sandboxed build environment would need network access declared, which `brew audit` flags |
| A tap is a plain git repo, so the same installation-token `git push` `pages_push` uses will work against it, with no Homebrew-specific API | Read `docs.brew.sh/Taps` and `/How-to-Create-and-Maintain-a-Tap`: a tap is "a Git repository... or even just a directory with files in it" | confirmed by documentation, not yet proven by an actual push | if false, M3's push step needs a different mechanism than `pages.sh`'s |

**Preconditions.** PR #50 merged into `main` (confirmed 2026-09-24: `origin/main` at `f08566b`,
carrying the ADR 28/29 report-threshold-check build model this plan's milestones will build
inside of). `dynamic.sh`/`constants.env` already select `PACKAGE_FORMATS=brew` on Darwin.

## References

### Research

| Question | Short answer | Evidence | Report |
|---|---|---|---|
| Has brew publishing ever worked in this repo? | No — every attempt stopped at a stub or a non-public channel | `scripts/publish-brew.sh` (deleted, commit `f36cce5`): `exit 1 "not implemented"`; `scripts/publish-brew-to-container.sh` (deleted): pushed to a local nginx container, not a real tap | this section |
| Does a git tag exist to package from? | No | `git tag -l` returns nothing | this section |
| Does a tap repo exist in the org? | No | `gh api orgs/thruput-io/repos --jq '.[] \| select(.name \| test("brew\|tap\|formula";"i"))'` returns nothing | this section |
| What must a Homebrew formula declare to build from source? | `url` (source tarball), `sha256`, `def install`, `test do`; a tap is a git repo named `homebrew-<name>`, consumed via `brew tap` or `brew install user/repo/formula` | `docs.brew.sh/Taps`, `docs.brew.sh/How-to-Create-and-Maintain-a-Tap`, `docs.brew.sh/Formula-Cookbook` (fetched 2026-09-24) | this section |
| What must the formula install, and where, to match apt's public-PATH contract? | Only `gettoken` and `integration-test-tool` on a public `PATH`; everything else off it | `scripts/test/packaging.bats` (existing test, already enforces this for apt's `.install` files) | this section |

Negative findings: `docs/adrs/0017-a-validator-brew-and-apt-can-carry.md` was read for prior
brew/apt parity reasoning; it concerns the JSON Schema validator, not packaging, and adds no
constraint here beyond confirming the project's general preference for build-from-source parity
between the two platforms.

### Rejected alternatives

| Alternative | Evidence gathered | Why rejected | Decision |
|---|---|---|---|
| Publish formulae to a private container (as `publish-brew-to-container.sh` did) | Removed from the tree; a URL only reachable from inside a Docker network is not a channel a real `brew install` can reach | Not a real distribution channel | historical, pre-dates this plan |
| Homebrew bottles | ADR 27 states "formula only... no bottle" | Out of this plan's scope by existing ADR; revisiting ADR 27 is a separate decision | pending, if raised |

## Discussions

The decision register: one row per non-trivial decision, in the order the decisions were taken.

| # | Decision | Question put to the human | Answer (verbatim) | Decided by | Rationale | Date |
|---|---|---|---|---|---|---|
| D1 | Tap repository is `thruput-io/homebrew-tap` | "What repository name/location should the tap live at (e.g. `thruput-io/homebrew-tap` vs `thruput-io/homebrew-gettoken`)?" | "1. is fine" | human | Accepts the first offered option. | 2026-09-24 |
| D2 | The tap mirrors apt's package boundaries, not a single monolithic formula | "Does the single-keg Homebrew model need its own ADR recording the intentional departure from ADR 21's per-contract packaging, or is it accepted as a platform difference without one?" | "just as apt" | human | Rejects the single-keg framing outright; the tap is to mirror apt's boundaries rather than diverge from them. Scope of "mirror" (installable components only vs. every apt package including contract-only stubs) is [open](#open-questions), pending the human's answer. | 2026-09-24 |
| D3 | A new git tag is cut on every merge to `main`; the version is repo-wide, not per-component, for now | "What is the source of truth for the formula's version — a git tag drives `src/debian/changelog`, the changelog drives the tag, or they are chosen independently per release?" | "New tag for each merge to main and versions stays repo wide for now" | human | The tag becomes the single source of truth for what every formula and the apt archive call "this version," deferring per-component versioning. | 2026-09-24 |
| D4 | Version = `{major}.{minor}` from `version.txt`, patch digit = the CI build number | "Is version/release lockstep automation... in scope for this plan, or does it belong to a later one?" | "A super simple one for now major/minor from a verion.txt then patch version as build numer" | human | In scope, deliberately minimal: a committed `version.txt` for the two digits a human chooses, the build number for the one that shouldn't need a commit. | 2026-09-24 |
| D5 | CI publishes the tap with the same installation-token `git push` mechanism `pages_push` uses for the apt archive | "What pushes the formula to the tap in CI — the same installation-token pattern `pages_push` uses for the apt archive, or something else?" | "apt if that is okey with brew?" | human, agent confirmed the mechanism is compatible | A Homebrew tap is a plain git repository (`docs.brew.sh/Taps`); no Homebrew-specific push API exists, so the existing pattern applies unchanged once the app has write access to the new repo. | 2026-09-24 |
| D6 | "Mirror apt" means a literal formula for every apt package (22, including the 10 contract-only ones), wired with `depends_on` exactly as apt wires them with `Depends` | "Does 'mirror apt's package boundaries' mean one formula per installable component, or a literal formula for all 22 apt packages including the ten that carry only a schema?" | "doesn't brew have deps?" / "it's kind of vital to this solution" | human | Confirmed from the Formula Cookbook: `depends_on "formula-name"` is a first-class formula dependency, the same mechanism `Depends` gives apt — there is no technical reason to collapse the graph. The human stressed the dependency wiring itself is load-bearing, not cosmetic: a set of 22 formulae with no real `depends_on` edges between them would not satisfy this decision. | 2026-09-24 |
| D7 | The black-box proof (Goal 2) invokes `dynamic.sh` + `src/integration-test/test.sh` directly on the CI runner; it never goes through `make test`. `test.sh` gains a `SETUP_COMMAND` value from `dynamic.sh` (mirroring `INSTALL_COMMAND`) for the one apt-specific step, so it stays linear rather than branching on `PACKAGE_FORMATS` itself | "What should the macOS CI job invoke instead of make test?" | "integration test runs a completely clean machine" / "mkae test is local environment only" | human | `make test` requires `make` and the whole Makefile dependency graph on the runner before anything installs — that is not the clean machine a real installer sees. `dynamic.sh` sourced directly needs only `bash`; `test.sh` then installs the product exactly as a user would, through the platform's own package manager. `test.sh` already avoids branching on `PACKAGE_FORMATS` (a prior version did and PR #50's review flagged it); a second per-platform value from `dynamic.sh` keeps that true for the tap-vs-sources-file step instead of adding an `if` to `test.sh`. | 2026-09-24 |

## Open questions

Empty — closed by [D6](#discussions).

## Execution Plan

Draft — presented in full for challenge before any step is implemented, per Phase 3.

### Goal coverage

| Goal | Delivered by |
|---|---|
| 1 | M1, M2, M3 |
| 2 | M2, M4 |
| 3 | M4 |

### Running all tests

`make unit lint` (quality gates, unchanged) for the build machine. For the black-box proof:
`source dynamic.sh && bash src/integration-test/test.sh` on a clean image — never `make test`
([D7](#discussions)). Both exist today; M4 is the milestone that points the macOS CI job at the
direct invocation instead of the placeholder step it has now.

### Milestone M1 — A version exists to tag and build from

**Delivers:** Goal 1 (a real source to build from)

**Steps**

1. Add `version.txt` at the repository root holding `MAJOR.MINOR` (starting `0.1`, matching
   `src/debian/changelog`'s current `0.1.0`).
2. Add a CI step, on push to `main`, that reads `version.txt`, appends the CI build number as the
   patch digit, and creates + pushes a git tag `v{major}.{minor}.{build}` ([D3](#discussions),
   [D4](#discussions)).
3. `dynamic.sh` or a new small script exposes the resolved version to the rest of the build the
   same way it exposes `BRANCH` today, so both `src/debian/changelog` and the formula generator
   (M2) read one value.

**Verification:** a merge to `main` produces a new git tag matching `v{version.txt}.{build
number}`; `git describe --tags` on that commit returns it.

### Milestone M2 — Formulae mirror apt's package graph, built from a real tag

**Delivers:** Goal 1 (full component set, real dependency graph), part of Goal 2 (installable
correctly)

**Steps**

1. Extract the per-contract dependency computation `scripts/packaging.sh` already does for
   `debian/control` into data both the deb and brew generators read, rather than duplicating the
   `uses`/`needs` logic.
2. Write a generator (parallel to `packaging.sh`'s `deb` arm, in the existing `PACKAGE_FORMATS`
   loop per ADR 29) that emits one `.rb` formula per apt package — the 12 installable components
   and the 10 contract-only packages — each `url`/`sha256` pointing at M1's tag, `depends_on`
   wiring mirroring apt's `Depends` exactly.
3. Each installable formula's `def install` builds only what that apt package builds (reusing
   `src/components/contract/build.sh` for `parse`/`format`) and installs only what that package's
   `.install` file names, so the public-PATH contract `packaging.bats` asserts for apt holds for
   brew too.
4. Replace `deliver-brew.sh`'s placeholder body with this generator; remove the
   `gettoken.rb.todo` emission.

**Verification:** `brew audit --new --formula` is clean on every generated formula in a scratch
tap; a new or extended `packaging.bats`-style assertion confirms the brew dependency graph matches
apt's `Depends` graph package-for-package.

### Milestone M3 — A real tap receives them

**Delivers:** Goal 1 (installable from a real channel)

**Steps**

1. Create `thruput-io/homebrew-tap` ([D1](#discussions)) and grant the GitHub App installation
   write access to it.
2. Replace `publish.sh`'s brew arm — which today only copies `gettoken.rb` into the `gh-pages`
   worktree and says publishing is not built yet (issue #53) — with a push of M2's generated
   `Formula/*.rb` into the tap repo, using the same installation-token mechanism `pages_push` uses
   ([D5](#discussions)), gated by `PACKAGE_FORMATS` on Darwin CI.

**Verification:** on a clean macOS guest, `brew tap thruput-io/tap && brew install gettoken`
succeeds and installs the dependency graph M2 built.

### Milestone M4 — CI proves the whole chain, replacing the placeholder

**Delivers:** Goal 2 (black-box proof), Goal 3 (real `macOS stable` job, closes issue #51)

**Steps**

1. `dynamic.sh` exposes a new per-platform value, `SETUP_COMMAND` (mirroring `INSTALL_COMMAND`):
   on Debian, the existing `curl … -o gettoken.sources` step; on Darwin, `brew tap
   thruput-io/tap`. This keeps `test.sh` linear rather than teaching it to branch on
   `PACKAGE_FORMATS` ([D7](#discussions)).
2. `test.sh` runs `$SETUP_COMMAND` where it currently hard-codes the apt sources-file write, then
   proceeds unchanged: put a super-token in the store, ask `gettoken` for a capability, run the
   tool on the narrow token that comes back.
3. Replace the placeholder `macOS stable` job in `verifications.yml` with: install only
   `git`/`ca-certificates` (no `make`), checkout, `source dynamic.sh`, `bash
   src/integration-test/test.sh` — installing `gettoken` from the tap M3 publishes.

**Verification:** `macOS stable` in CI goes green on that real flow, invoked the same way (never
`make test`) as [D7](#discussions) requires; it fails if the tap, a formula, or the dependency
graph is broken, the same way `Debian stable` fails today.
