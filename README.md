# Rust crate to workspace

Restructure your project with rust crate to workspace.

---

## 🚀 Usage

Run

```shell
curl https://raw.githubusercontent.com/Alirex/rust_crate_to_workspace/refs/heads/main/scripts/rust_crate_to_workspace.sh | bash -s
```

---

## 📝 Details

You started your project as crate, but now you want to use it as a workspace?

You can do it simply with this tool.

It is a relatively simple bash script.

It restructures your project to be a workspace.

Your crate is moved to "rust" folder. This can be customized via argument. This folder is marked as a folder for
workspace members.

Moved:

- src (with content)
- Cargo.toml

Nothing else is moved. Because it is less predictable.

Commit the changes after running the script.

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

### Register pre-commit

```shell
pre-commit install
```

### Run pre-commit

```shell
pre-commit run --all-files
```

## Inspired by:

- https://github.com/rust-lang/cargo/issues/7713

## Can be interesting for you:

- [Rust book: Cargo workspaces](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html)
- [Cargo book: Workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)
- [cargo-workspaces](https://crates.io/crates/cargo-workspaces)
  - A tool that optimizes the workflow around cargo workspaces
