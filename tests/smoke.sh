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

echo "OK"
