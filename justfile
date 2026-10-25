# rust_crate_to_workspace recipes. Run `just` for the list. Prefixes: q- quality, dev- setup, rel- release.

set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
default:
    @just --list

# Full gate: every prek hook on all files, then the smoke test. Run again if fixers changed files.
[group('quality')]
q-check: q-fast q-test

# Fast loop: prek hooks only.
[group('quality')]
q-fast:
    SKIP=pre-commit-update prek run --all-files

# Smoke test: run the script on scratch `cargo new` crates and `cargo check` the result.
[group('quality')]
q-test:
    tests/smoke.sh

# Scan the whole git history for leaked secrets (gitleaks; monthly and when adopting).
[group('quality')]
q-secrets:
    prek run gitleaks-history --hook-stage manual --all-files

# Install the git hooks (once per clone).
[group('dev')]
dev-hooks:
    prek install

# Fail unless the tag matches the newest version in CHANGELOG.md: `just rel-check v0.1.0`.
[group('release')]
rel-check tag:
    #!/usr/bin/env bash
    set -euo pipefail
    version="$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | tr -d '#[] ')"
    if [[ "{{ tag }}" != "v${version}" ]]; then
        echo "Tag {{ tag }} differs from the changelog version v${version}" >&2
        exit 1
    fi
    echo "ok: v${version}"
