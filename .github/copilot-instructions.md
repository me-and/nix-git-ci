# Copilot instructions

## Repository purpose

This repository tests the Nixpkgs packaging of Git against Git's maintenance
and development branches, ahead of the release Nixpkgs currently packages. That
early warning serves two purposes: Nixpkgs-specific bugs introduced upstream can
be reported to the Git project before they reach a release, and packaging
changes required by upstream changes can be identified and tested in advance of
that release.

The flake tracks `gitMain` (`master`), `gitNext` (`next`), and `gitMaint` (the
current maintenance branch, whose exact name changes over time) as non-flake
inputs, and combines each source with Nixpkgs' `gitMinimal`, `git`, `gitSVN`,
and `gitFull` package definitions.

## Build, test, and formatting commands

Run commands from the repository root with Nix flakes enabled:

```sh
# Build the complete check matrix for the current system.
nix flake check

# Evaluate all systems without building and continue after failures.
nix flake check --no-build --all-systems --keep-going

# Build/run one targeted package check (replace the branch/package/system).
nix build '.#checks.x86_64-linux."gitMain/git/package"'

# List all package and check output names.
nix flake show --all-systems

# Format the Nix source in place.
nix fmt

# Format in place, but exit non-zero if anything changed or errored (the CI
# form).
nix fmt -- --ci
```

The targeted check path is made of a branch (`gitMain`, `gitNext`, or
`gitMaint`) and package (`git`, `gitMinimal`, `gitSVN`, or `gitFull`), followed
by `/package` under `checks.<system>`. The checks build the package and run its
Nixpkgs/upstream install checks. GitHub Actions runs the matrix regularly, on
both `x86_64-linux` and `aarch64-linux`.

When intentionally refreshing upstream inputs, use:

```sh
nix flake update --commit-lock-file
```

This updates `flake.lock`; review the resulting source revisions and build
impact together.

## Architecture and data flow

- `flake.nix` uses `flake-utils.lib.eachSystem` for `x86_64-linux` and
  `aarch64-linux`, importing the corresponding Nixpkgs revision for each
  system.
- `patchGit` applies attribute overrides to a Nixpkgs Git derivation, then
  applies ordinary package overrides. These fall into two groups. Some are
  permanent to this repository, because they only make sense here: building
  from the tracked branch source, adding the branch and short revision to the
  package name, enabling the install checks, dropping passthru tests that would
  otherwise exercise an unrelated base Git, and the maintenance branch's
  version check. The rest work around differences between Nixpkgs' packaging
  and the branches being built, and are expected to migrate into Nixpkgs and
  then be deleted from here.
- `gitSourcePatchers` holds the per-branch equivalents: compatibility fixes
  that only apply to some upstream branches, likewise expected to become
  unnecessary as Nixpkgs and upstream releases catch up. It also attaches the
  maintenance branch's `maintVersionCheck` passthru test, which compares the
  branch's generated version with Nixpkgs' Git major/minor version so the two
  cannot silently drift apart.
- Each override in `flake.nix` carries a comment saying why it exists and
  whether it is permanent or awaiting adoption by Nixpkgs; keep that true when
  adding or changing overrides.
- `legacyPackages` is the source structure, `packages` is its flattened public
  form, and `checks` wraps every package with its package build plus passthru
  tests. The formatter is Nixpkgs' `nixfmt-tree`.
- `.github/workflows/ci.yml` runs the build/check matrix and a separate
  formatting/evaluation job. `.github/workflows/updateflake.yml` periodically
  updates and pushes the lock file, so dependency revisions are intentionally
  automated.

## Repository-specific conventions

- Keep branch identifiers and upstream source inputs aligned: changes to a
  tracked Git branch normally require changing the corresponding input and
  preserving the branch name in derivation names. The maintenance branch input
  is expected to be repointed as Git's maintenance line moves on.
- Put changes that should affect every Git build in `defaultAttrOverrides` (or
  `defaultOverride`) inside `patchGit`; use `gitSourcePatchers` only for
  changes that apply to specific upstream branches.
- Keep each `override`/`overrideAttrs` minimal and self-contained, fixing one
  problem apiece, rather than bundling unrelated fixes together.
- Write overrides with an eye to how they would be incorporated into the
  underlying Nixpkgs package definitions later, and remove them from here once
  Nixpkgs has taken them.
- Where a problem can be fixed several ways, prefer the fix that moves the
  build closer to how Git is normally packaged and built upstream. Removing or
  disabling tests is a last resort.
- Most changes here need `overrideAttrs`, since they adjust derivation
  attributes, but prefer a plain `override` of package arguments wherever the
  fix can be expressed that way; this follows the existing
  `applyAttrOverrides`/`applyOverrides` split.
- Preserve the flattened output shape and package names because CI and targeted
  builds address checks through paths such as
  `checks.<system>."gitMain/git/package"`.
- Treat comments in `flake.nix` describing Nixpkgs or upstream fixes as
  maintenance context: they record why a workaround exists and when it can go
  away, so update or remove them once the upstream/Nixpkgs condition they
  document changes.
- Keep formatting changes produced by `nix fmt`; CI expects the formatter's
  `--ci` check to pass.
