#!/usr/bin/env bash
# Smoke test: run the script on scratch `cargo new` crates and check the result.
# Usage: tests/smoke.sh   (needs cargo and git)

set -o errexit
set -o pipefail
set -o nounset

here="$(cd "$(dirname "$0")/.." && pwd -P)"
script="${here}/scripts/rust_crate_to_workspace.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

new_repo() {
  local dir="${tmp}/$1"
  cargo new --quiet --bin "${dir}"
  git -C "${dir}" config user.email test@example.com
  git -C "${dir}" config user.name test
  git -C "${dir}" add -A
  git -C "${dir}" commit --quiet -m init
  echo "${dir}"
}

# 1. Happy path (default folder), then idempotence.
repo="$(new_repo demo)"
(cd "${repo}" && "${script}")
[[ -f ${repo}/rust/demo/Cargo.toml ]] || fail "crate Cargo.toml not moved"
[[ -f ${repo}/rust/demo/src/main.rs ]] || fail "src not moved"
grep -q '^\[workspace\]' "${repo}/Cargo.toml" || fail "no workspace Cargo.toml"
git -C "${repo}" diff --cached --quiet -- Cargo.toml && fail "Cargo.toml not staged"
(cd "${repo}" && cargo check --quiet) || fail "workspace does not build"
git -C "${repo}" add -A && git -C "${repo}" commit --quiet -m ws
if (cd "${repo}" && "${script}") 2>/dev/null; then fail "second run must refuse"; fi

# 2. Custom folder and path argument.
repo2="$(new_repo other)"
"${script}" "${repo2}" crates
[[ -f ${repo2}/crates/other/Cargo.toml ]] || fail "custom folder ignored"
(cd "${repo2}" && cargo check --quiet) || fail "custom workspace does not build"

# 3. Dirty tree is refused.
repo3="$(new_repo dirty)"
echo "// x" >>"${repo3}/src/main.rs"
if "${script}" "${repo3}" 2>/dev/null; then fail "dirty tree must be refused"; fi
[[ -f ${repo3}/Cargo.toml ]] || fail "dirty run changed files"

# 4. Not a crate.
mkdir "${tmp}/empty" && git -C "${tmp}/empty" init --quiet
if "${script}" "${tmp}/empty" 2>/dev/null; then fail "missing Cargo.toml must be refused"; fi

# 5. A crate with tests/, build.rs, examples/, benches/ and a root README named by `readme =`.
repo5="$(new_repo full)"
(
  cd "${repo5}"
  mkdir tests examples benches
  cat >build.rs <<'RS'
fn main() {
    println!("cargo:rerun-if-changed=build.rs");
}
RS
  cat >tests/it.rs <<'RS'
#[test]
fn integration() {
    assert_eq!(2 + 2, 4);
}
RS
  printf 'fn main() {}\n' >examples/ex.rs
  printf 'fn main() {}\n' >benches/b.rs
  echo "# full" >README.md
  sed -i.bak 's/^edition.*/&\nreadme = "README.md"\nbuild = "build.rs"\n\n[[bench]]\nname = "b"\npath = "benches\/b.rs"\nharness = false/' Cargo.toml
  rm -f Cargo.toml.bak
  git add -A && git commit --quiet -m extras
  "${script}"
)
for moved in tests/it.rs build.rs examples/ex.rs benches/b.rs src/main.rs README.md; do
  [[ -f ${repo5}/rust/full/${moved} ]] || fail "${moved} not in the crate"
done
for stayed in tests examples benches build.rs; do
  [[ ! -e ${repo5}/${stayed} ]] || fail "${stayed} left at the root"
done
[[ -f ${repo5}/README.md ]] || fail "root README must stay"
(cd "${repo5}" && cargo check --quiet --all-targets) || fail "extras: cargo check --all-targets failed"
(cd "${repo5}" && cargo test --quiet) || fail "extras: cargo test failed"

# 6. Paths that would not move are refused, and nothing changes.
repo6="$(new_repo outside)"
printf '\n[[bin]]\nname = "x"\npath = "tools/x.rs"\n' >>"${repo6}/Cargo.toml"
mkdir "${repo6}/tools" && printf 'fn main() {}\n' >"${repo6}/tools/x.rs"
git -C "${repo6}" add -A && git -C "${repo6}" commit --quiet -m tools
if "${script}" "${repo6}" 2>/dev/null; then fail "target path outside the moved set must be refused"; fi
[[ -d ${repo6}/src && ! -e ${repo6}/rust ]] || fail "refused run changed files"

repo7="$(new_repo parentreadme)"
sed -i.bak 's/^edition.*/&\nreadme = "..\/README.md"/' "${repo7}/Cargo.toml"
rm -f "${repo7}/Cargo.toml.bak"
git -C "${repo7}" add -A && git -C "${repo7}" commit --quiet -m readme
if "${script}" "${repo7}" 2>/dev/null; then fail "readme outside the crate must be refused"; fi

# 8. Path dependencies (inline and dotted table) are rewritten; Cargo's automatic README is copied.
mkdir -p "${tmp}/sib/src"
printf '[package]\nname = "sib"\nversion = "0.1.0"\nedition = "2021"\n' >"${tmp}/sib/Cargo.toml"
printf 'pub fn one() -> u8 {\n    1\n}\n' >"${tmp}/sib/src/lib.rs"
repo8="$(new_repo pathdeps)"
(
  cd "${repo8}"
  printf 'sib = { path = "../sib" }\n\n[build-dependencies.sib]\npath = "../sib"\n' >>Cargo.toml
  printf 'fn main() {\n    assert_eq!(sib::one(), 1);\n}\n' >src/main.rs
  echo "# pathdeps" >README.md
  git add -A && git commit --quiet -m deps
  "${script}" "${repo8}" crates/rust
)
member8="${repo8}/crates/rust/pathdeps"
[[ $(grep -c 'path = "../../../../sib"' "${member8}/Cargo.toml") -eq 2 ]] || fail "path dependencies not rewritten"
[[ -f ${member8}/README.md && -f ${repo8}/README.md ]] || fail "automatic README not copied"
(cd "${repo8}" && cargo check --quiet) || fail "path dependencies: workspace does not build"

echo "OK"
