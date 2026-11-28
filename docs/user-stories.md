# User stories: rust_crate_to_workspace

Reviewed against the code on 2026-11-28.

One entry per goal a person or agent reaches with rust_crate_to_workspace, the Given/When/Then lines that confirm it, and the
test that proves it. Status: `built` (every line names a test that exists), `partial`, `planned`, `gap`.

The tests named below are numbered cases in `tests/smoke.sh`, named by their comment line. `dossier check` finds tests only by function name in test files, so these entries say `partial` until it reads shell test cases.

## Index

| Id   | Goal                                            | Actor          | Status  |
| ---- | ----------------------------------------------- | -------------- | ------- |
| US-1 | turn a crate into a workspace                   | Rust developer | partial |
| US-2 | not lose work on a repository that is not ready | Rust developer | partial |
| US-3 | keep path dependencies working after the move   | Rust developer | partial |

## US-1: turn a crate into a workspace

```yaml
schema: 1
id: US-1
actor: Rust developer
goal: turn a crate into a workspace
why: so that a second crate can be added without moving files by hand
status: partial
accept:
  - gwt: Given a clean crate, when the script runs, then the crate is under rust/<crate> and the workspace builds.
    test: Happy path (default folder), then idempotence
  - gwt: Given a folder argument, when the script runs, then the members go to that folder.
    test: Custom folder and path argument
proof:
  cmd: tests/smoke.sh
```

## US-2: not lose work on a repository that is not ready

```yaml
schema: 1
id: US-2
actor: Rust developer
goal: not lose work on a repository that is not ready
why: so that a run on the wrong tree changes nothing
status: partial
accept:
  - gwt: Given uncommitted changes, when the script runs, then it refuses and changes nothing.
    test: Dirty tree is refused
  - gwt: Given a folder without Cargo.toml, when the script runs, then it refuses.
    test: Not a crate
proof:
  cmd: tests/smoke.sh
```

## US-3: keep path dependencies working after the move

```yaml
schema: 1
id: US-3
actor: Rust developer
goal: keep path dependencies working after the move
why: so that the workspace builds without manual fixes
status: partial
accept:
  - gwt: Given path dependencies, when the crate moves, then their paths are rewritten.
    test: Path dependencies (inline and dotted table) are rewritten
proof:
  cmd: tests/smoke.sh
```

## Retired

None.
