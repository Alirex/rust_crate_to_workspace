# rust_crate_to_workspace: instructions for AI agents

A single bash script, `scripts/rust_crate_to_workspace.sh`, that turns a git-tracked Rust crate into a cargo
workspace (`src` and `Cargo.toml` move to `<folder>/<crate>/` with `git mv`, a workspace `Cargo.toml` is staged).
It runs from `curl | bash`, so it must stay a single self-contained file.

## Commands

[just](https://just.systems) is the entry point (`just` lists recipes).

- `just q-check`: the full gate (every prek hook on all files, then `tests/smoke.sh`). It must pass before committing.
  Prek fixers rewrite files; run it again until it passes.
- `just q-test`: `tests/smoke.sh`, runs the script on scratch `cargo new` crates and `cargo check`s the result.
- `just q-secrets`: gitleaks over the whole history; a real hit is rotated, never allowlisted.
- `just rel-check vX.Y.Z`: the tag must match the top version in `CHANGELOG.md`.
- Never commit the version bump of the `pre-commit-update` hook unasked.

## Rules

- Script: `set -o errexit -o pipefail -o nounset`, quoted expansions, bash 3.2 (macOS) and BSD/GNU portable tools
  only (no `mkdir --parents`, `grep \s`, `realpath`). shellcheck `enable=all`, shfmt. Fix the warning, do not silence it.
- The script refuses (exit 1, message on stderr) on a dirty git tree, a missing `Cargo.toml`, an existing
  `[workspace]` or an existing target folder. Keep these refusals and cover each in `tests/smoke.sh`.
- Behaviour changes update the README and `CHANGELOG.md` (Keep a Changelog, `Unreleased` section).
- Release: a `v*` tag plus a GitHub release made from the changelog section (`gh release create`); there is no
  package registry. The version lives only in `CHANGELOG.md`.
- CI actions are pinned to a full commit SHA with a `# vX.Y.Z` comment; Dependabot keeps them and the hooks current.
- Small personal repo: commit to `main` directly, conventional commits.

## Practices

Reasoning lives in HQ; these are the binding short versions.

- [quality-gate](https://github.com/evocaslab/hq/blob/main/practices/quality-gate.md)
- [just-task-runner](https://github.com/evocaslab/hq/blob/main/practices/just-task-runner.md)
- [agent-instructions](https://github.com/evocaslab/hq/blob/main/practices/agent-instructions.md)
- [supply-chain-security](https://github.com/evocaslab/hq/blob/main/practices/supply-chain-security.md)
- [releases-and-versions](https://github.com/evocaslab/hq/blob/main/practices/releases-and-versions.md)
- [testing](https://github.com/evocaslab/hq/blob/main/practices/testing.md)
- [gitignore-and-ide](https://github.com/evocaslab/hq/blob/main/practices/gitignore-and-ide.md)
