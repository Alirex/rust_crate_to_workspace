# Rust crate to workspace

Restructure your project with rust crate to workspace.

---

## 🚀 Usage

Run in the root of a git repository with a clean working tree:

```shell
curl https://raw.githubusercontent.com/Alirex/rust_crate_to_workspace/refs/heads/main/scripts/rust_crate_to_workspace.sh | bash -s
```

Arguments (pass them after `bash -s --`): the repository path (default: current directory) and the members folder
(default: `rust`).

```shell
curl https://raw.githubusercontent.com/Alirex/rust_crate_to_workspace/refs/heads/main/scripts/rust_crate_to_workspace.sh | bash -s -- . crates
```

Example result for a crate `demo`:

```text
Cargo.toml          (new, workspace)
rust/demo/Cargo.toml
rust/demo/src/main.rs
(and rust/demo/tests, benches, examples, build.rs when the crate has them)
```

---

## 📝 Details

You started your project as crate, but now you want to use it as a workspace?

You can do it simply with this tool.

It is a relatively simple bash script.

It restructures your project to be a workspace.

Your crate is moved to "rust" folder. This can be customized via argument. This folder is marked as a folder for
workspace members.

Moved (with `git mv`, only what exists):

- src (with content)
- Cargo.toml
- tests, benches, examples and build.rs

Copied:

- the file named by `readme = "..."` in `[package]` (if it is a path inside the crate and not already moved), or,
  without a `readme` key, the `README.md`, `README.txt` or `README` Cargo would pick by itself. It is copied, not
  moved, because a README at the root is usually also the repository README. Delete either copy if you do not need
  both.

Nothing else is moved: `Cargo.lock`, `.git*`, `rust-toolchain.toml`, `.cargo/`, CI config and `target/` stay at the
root. Paths in `Cargo.toml` (`build`, `[lib]`/`[[bin]]`/`[[test]]`/`[[example]]`/`[[bench]]` `path`) stay valid, as
they are relative to the moved manifest. Relative path dependencies (`path = "../x"` in any `dependencies` table or
`[patch.*]`) get one `../` per added folder level, so `rust/<crate>` turns `../x` into `../../../x`. `include` and
`exclude` globs are not rewritten: the script warns when they exist.

Added:

- Cargo.toml (for workspace)

Extra:

- new cargo.toml is added to git staging area.

Now you can commit the changes after running the script.
Because, you may want to check the changes before committing and set specific commit message.

It is safe to run it multiple times. If a workspace is already created, it will not be recreated.

It refuses (exit code 1) when the git tree is dirty, `Cargo.toml` is missing, a `[workspace]` already exists, the
target folder exists, or a `readme`, `build` or target `path` points outside the crate or outside the moved
folders (the workspace would not build). It needs bash 3.2+ (macOS works), git and a POSIX awk.

### Why move in the "rust" folder?

Because, in my case, I have a lot of content in the root folder.
Sometimes, the project includes different languages.
So, if I can, I will group some things in the related folders.
If it matches other boundaries.

Also, I can simply add new members of the workspace in the future.
They will be included by default.

```shell
cargo new --lib rust/my_lib
```

---

## 🛠️ Development

[just](https://just.systems), [prek](https://github.com/j178/prek) and a Rust toolchain are needed.

```shell
just dev-hooks   # install the git hooks
just q-check     # the gate: all hooks, then the smoke test (tests/smoke.sh)
```

## License

[MIT](LICENSE.txt).

## Inspired by

- <https://github.com/rust-lang/cargo/issues/7713>

## Can be interesting for you

- [Rust book: Cargo workspaces](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html)
- [Cargo book: Workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)
- [cargo-workspaces](https://crates.io/crates/cargo-workspaces)
  - A tool that optimizes the workflow around cargo workspaces
