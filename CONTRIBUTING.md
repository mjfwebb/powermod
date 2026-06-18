# Contributing

powermod is a single bash script (`powermod`) plus an installer and tests. Bug
reports, fixes, and tweaks are welcome.

## Dev setup

There is nothing to build. Clone, edit `powermod`, and run it straight from the
working tree:

```bash
./powermod
```

The installed copy under `~/.local/bin` is a snapshot; re-run
`install -Dm755 powermod ~/.local/bin/powermod` to update it, or re-run the
`install.sh` one-liner from the README.

Tools needed:

| Tool | Used for |
|------|----------|
| `bash` | the script itself |
| `power-profiles-daemon` (`powerprofilesctl`) | switching the three real profiles |
| [`bats`](https://github.com/bats-core/bats-core) | running the tests |
| [`shellcheck`](https://www.shellcheck.net/) | linting |

On Debian/Ubuntu: `sudo apt install bats shellcheck power-profiles-daemon`.

Note that powermod targets one machine's knobs: a Lenovo ThinkPad P15 Gen 2i
with an `acpi` `platform_profile` and per-CPU `energy_performance_preference`.
The custom (`quiet`/`snappy`) levels write those sysfs paths and re-exec under
`sudo`; the three PPD levels go through `powerprofilesctl`.

## Tests

```bash
bats tests
```

The suite lives in `tests/powermod.bats`. The script returns early when sourced
(the guard sits just above the `MODE=` dispatch), so the tests source it and
call its functions directly. This puts a constraint on new code: above the
guard, only definitions and read-only discovery; anything that mutates state or
dispatches goes below it.

The tests cover the pure logic, chiefly `decode_mode`, which maps a
`platform_profile`/EPP pair to a ladder-level label. It is kept free of any
sysfs read so every branch can be exercised by passing values in. The live
paths that read `/sys` and shell out to `powerprofilesctl`/`sudo` are exercised
by hand on the machine rather than in CI. Add a test for new pure logic where
you can: factoring a decoder so it reads its inputs as arguments (as
`decode_mode` does) makes it testable without touching the hardware.

## Linting

```bash
shellcheck powermod install.sh
```

The script is shellcheck-clean and CI enforces that. If shellcheck flags
something intentional, add a `# shellcheck disable=SCxxxx` directive on the line
above it with a short reason. Don't add global ignore lists.

## CI

`.github/workflows/ci.yml` runs bats and shellcheck on every push to `main` and
on every pull request. Both jobs must pass.

## Style

Match the existing code:

- bash; keep it small and readable.
- Comments explain why (the EPP gap the custom modes target, why the active
  mode is decoded from the real knobs rather than the PPD label), not what the
  next line does.
- Missing sensors or commands (no `powerprofilesctl`, an unreadable
  `platform_profile`) must degrade gracefully: print `?`, never crash.

## Pull requests

- Keep PRs focused; separate refactors from behavior changes.
- Update the README when levels, flags, or output change.
- **Don't touch the `VERSION=` line in a feature or fix PR.** It is bumped once
  per release in its own commit on `main` (see Releases). Two open PRs that both
  edit it would otherwise conflict on the version, and merge order would
  silently decide the number.

## Releases

The version lives in one place: the `VERSION=` line in `powermod` (read, not
executed, by `install.sh` to report what an update did). It is owned by `main`,
not by PRs, so that parallel PRs never contend over the number. CI enforces this
from both sides:

- The `no-version-change` job fails any PR whose diff touches the `VERSION=`
  line.
- The `release` job runs on every push to `main` (after tests and lint pass).
  When `powermod` changed since the last tag, it cuts a release.

Nobody edits the `VERSION=` line by hand. The `release` job computes the next
number from the last tag and the bump level, writes it, commits, and tags
`vX.Y.Z`. The bump level comes from a label on the PR, and every PR must carry
exactly one (the `bump-label` check fails and comments otherwise):

| PR label | Effect | Use for |
|----------|--------|---------|
| `bump:patch` | patch release | bug fixes, internal changes |
| `bump:minor` | minor release | new user-facing behavior |
| `bump:major` | major release | breaking changes |
| `bump:none` | no release | docs, CI, comments (nothing users run) |

`major` wins over `minor` over `patch` if several are somehow present. The
`bump-label` check re-runs when you add or change the label, so a red check goes
green once you pick one.
