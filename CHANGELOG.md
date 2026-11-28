# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- The README downloads the script, shows it and then runs it, instead of piping `curl` into `bash`.
- Public-repo docs: brand kit, `ARCHITECTURE.md`, user stories, a decision record, `dossier.yaml`, an agent skill in
  `skills/rust-crate-to-workspace/`, and a release workflow that creates the GitHub release from a `v*` tag.

- Git history rewritten on 2026-11-28 to replace a personal commit e-mail: every commit SHA changed, and the tag
  `v0.1.0` keeps its name but points at the rewritten commit. A download URL that names a commit SHA needs the
  tag or `main` instead. A clone from before that date needs `git fetch --force --tags` and a reset of `main`.

## [0.2.0] - 2026-10-25

### Added

- MIT license (`LICENSE.txt`, #2).
- The script also moves `tests/`, `benches/`, `examples/` and `build.rs` into the member folder, and copies the file
  named by `readme =`; it refuses when a `readme`, `build` or target `path` points outside the crate or outside the
  moved set (B-261025-crate-to-workspace-extra-dirs).
- Relative path dependencies are rewritten for the member folder, Cargo's automatic README (no `readme` key) is
  copied, and `include`/`exclude` get a warning (B-261025-crate-to-workspace-v020).

## [0.1.0] - 2026-10-25

First tagged version.

### Added

- `scripts/rust_crate_to_workspace.sh`: moves `src` and `Cargo.toml` into `<folder>/<crate>/` (default folder `rust`)
  and stages a workspace `Cargo.toml` with `<folder>/*` as members.
- Smoke test (`tests/smoke.sh`) and CI on Linux and macOS.

### Fixed

- The dirty git tree check never fired; it now refuses on any uncommitted change.
- Refuses when the target folder already exists, outside a git repository root, or without a `[package]` name.
- Works with bash 3.2 and BSD tools (no GNU-only `mkdir --parents`, `\s` in grep and sed, `realpath`).
- Errors go to stderr.
