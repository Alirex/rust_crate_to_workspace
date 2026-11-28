---
name: rust-crate-to-workspace
description: Restructure a single Rust crate into a cargo workspace with rust_crate_to_workspace.sh. Use when the user asks to convert a crate to a workspace, add a second crate to a single-crate repo, or move a crate under crates/ or rust/.
---

# rust_crate_to_workspace

Run it in the root of a git repository that holds one crate, with a clean working tree:

```shell
curl -fsSLO https://raw.githubusercontent.com/Alirex/rust_crate_to_workspace/main/scripts/rust_crate_to_workspace.sh
less rust_crate_to_workspace.sh            # read it before running it
bash rust_crate_to_workspace.sh . crates   # repo path, members folder (default: rust)
rm rust_crate_to_workspace.sh
```

Then review `git diff --cached` and run `cargo check --workspace` before committing; the script stages, it never
commits. It refuses (exit 1) on a dirty tree, a missing `Cargo.toml`, an existing `[workspace]` or an existing
target folder: fix the cause, do not work around the refusal. Never pipe the download into a shell.

## Rules

- This skill runs no scripts and fetches nothing; it tells you which command or API to use.
- Read the README before you change how the project is used; the repo's own rules for agents are in AGENTS.md.
