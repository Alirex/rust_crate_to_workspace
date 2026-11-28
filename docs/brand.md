# Brand book: rust_crate_to_workspace

Name: `rust_crate_to_workspace`. Tagline: "One crate in, one workspace out." The name, colours, fonts and marks are one source,
[brand/brand.yaml](../brand/brand.yaml), with the master SVGs in [brand/masters/](../brand/masters/); this page is the
prose around them. The name says what it does; there is no package to publish, the script is the release.

## Mission

Turn a git-tracked Rust crate into a cargo workspace with one script, keeping the git history of every moved file.

## Vision

Growing a crate into a workspace is a reviewed git diff, not an afternoon of moving files by hand.

## Audience

Rust developers whose single crate needs a second member (a library, a CLI, a test helper). Second: AI agents asked to restructure a crate, which should run the script and review the staged diff instead of moving files.

## Values

1. **Refuse rather than guess.** A dirty tree, an existing workspace or a target folder that exists stops the run.
2. **History kept.** Files move with `git mv`; the result is staged for review, never committed.
3. **One file.** A single bash 3.2 script with POSIX tools, on Linux and macOS.

## Voice

Plain and exact: say what the tool does to which file, with the command that shows it. No marketing words.

| Do                                                      | Do not                                                 |
| ------------------------------------------------------- | ------------------------------------------------------ |
| Write "`src` moves to `rust/<crate>/src` with `git mv`" | Write "magically converts your project"                |
| Keep the name in code type: `rust_crate_to_workspace`   | Capitalise it, translate it or add a logo-style suffix |

## Logo rules

The mark is one box that splits into two in the ink colour, with one dot in the accent colour. Use it as supplied, on the paper
colour or a calm background; keep a quarter of its width free on every side; 16 px is the smallest size (use the small
mark there). Do not stretch, rotate, recolour or add effects. The artwork is CC-BY-4.0; a fork uses its own name and
mark.
