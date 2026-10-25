#!/usr/bin/env bash
# Convert a single Rust crate (git repository) into a cargo workspace.
#
# Usage: rust_crate_to_workspace.sh [path_to_repo] [folder_for_members]
#   path_to_repo        the crate's repository root (default: current directory)
#   folder_for_members  folder that gets the crate and holds future members (default: rust)
#
# Moves src/ and Cargo.toml to <folder>/<crate_name>/ with `git mv`, writes a workspace Cargo.toml and stages it.
# Refuses on a dirty git tree, a missing Cargo.toml, an existing [workspace] or an existing target folder.
# Works with bash 3.2 (macOS) and GNU tools.

set -o errexit
set -o pipefail
set -o nounset

die() {
  echo "$1 Refusing to evaluate." >&2
  exit 1
}

path_to_main_repo="${1:-$(pwd)}"
parent_folder_name="${2:-rust}"

[[ -d ${path_to_main_repo} ]] || die "'${path_to_main_repo}' is not a directory."
path_to_main_repo="$(cd "${path_to_main_repo}" && pwd -P)"
cd "${path_to_main_repo}"

echo "Creating workspace in ${path_to_main_repo}"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not a git repository."
[[ "$(git rev-parse --show-toplevel)" == "${path_to_main_repo}" ]] || die "Not the root of the git repository."

if [[ -n "$(git status --porcelain)" ]]; then
  die "Git repository is dirty."
fi

path_to_root_toml="${path_to_main_repo}/Cargo.toml"
[[ -f ${path_to_root_toml} ]] || die "Cargo.toml not found."

if grep -Eq '^[[:space:]]*\[workspace\]' "${path_to_root_toml}"; then
  die "Workspace already exists."
fi

# The first `name = "..."` inside the [package] table.
crate_name="$(awk '
  /^[[:space:]]*\[/ { in_package = ($0 ~ /^[[:space:]]*\[package\]/) }
  in_package && /^[[:space:]]*name[[:space:]]*=/ {
    sub(/^[^"]*"/, "")
    sub(/".*$/, "")
    print
    exit
  }
' "${path_to_root_toml}")"
[[ -n ${crate_name} ]] || die "No [package] name in Cargo.toml."

echo "Name of the crate is: '${crate_name}'"

new_folder_for_crate="${path_to_main_repo}/${parent_folder_name}/${crate_name}"
[[ ! -e ${new_folder_for_crate} ]] || die "'${new_folder_for_crate}' already exists."
[[ -d src ]] || die "src folder not found."

mkdir -p "${new_folder_for_crate}"

echo "Moving crate to ${new_folder_for_crate}"
git mv src Cargo.toml "${new_folder_for_crate}/"

cat >"${path_to_root_toml}" <<TOML
[workspace]
resolver = "2"

members = [
    "${parent_folder_name}/*",
]
TOML

git add -- "${path_to_root_toml}"
echo "Done. Review with 'git status' and commit."
