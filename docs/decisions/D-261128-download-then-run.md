---
id: D-261128-download-then-run
status: accepted
date: 2026-11-28
reopen_when: the script is published as a package (crates.io binary or a release asset with a checksum)
---

# Download the script, read it, then run it; no pipe to a shell

## Context

The README used to pipe the `curl` download straight into `bash -s`. A pipe to a shell runs whatever the server sends, gives the reader no chance to see it, and can run a partly downloaded file. The public-repo standard's agent rules flag the pattern, because agents copy README commands.

## Drivers

- the user sees the code before it runs
- the command stays short enough to copy
- agents copy README commands as they are

## Considered options

| Option                           | Fits the drivers | Cost          | Hard to undo | Evidence                                     |
| -------------------------------- | ---------------- | ------------- | ------------ | -------------------------------------------- |
| **download, read, run** (chosen) | yes              | one more line | no           | public-repo standard, agent integration rule |
| keep the pipe into a shell       | no review        | none          | no           | the same rule flags it                       |
| publish a cargo binary           | yes              | a Rust port   | yes          | none yet                                     |

## Decision

In the context of a one-file bash tool, facing the risk of running unseen code, we chose to download the file, read it and then run it, over a pipe to a shell, to achieve a reviewed run, accepting one more line in the README.

## Consequences

- Good: the user and any agent see the script before it runs; a partial download fails to run instead of half-running.
- Bad: two commands instead of one.

## Confirmation

The bulwark public profile and the public-ready check flag a download piped into a shell in the docs.

## Sources

- Public-repo standard, agent integration rule (no pipe to a shell in docs)
