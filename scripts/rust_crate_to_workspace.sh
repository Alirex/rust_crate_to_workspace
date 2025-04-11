#!/usr/bin/env bash

# [bash_init]-[BEGIN]
# Exit whenever it encounters an error, also known as a non–zero exit code.
set -o errexit
# Return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status,
#   or zero if all commands in the pipeline exit successfully.
set -o pipefail
# Treat unset variables and parameters other than the special parameters ‘@’ or ‘*’ as an error when performing parameter expansion.
set -o nounset
# [bash_init]-[END]

#if [[ -n "$(git status -s)" ]]; then
#  echo "Git repository is dirty. Refusing to evaluate."
#  exit 1
#fi

# Check if the script has anything uncommitted, except for the this script

name_of_script="$(basename "$0")"
# shellcheck disable=SC2143
if [[ -n "$(git status --short | grep --quiet --invert-match "${name_of_script}")" ]]; then
  echo "Git repository is dirty. Refusing to evaluate."

  exit 1
fi

# path_to_main_repo is current working directory or the 1st argument.
# Make this path is absolute with resolution
path_to_main_repo="$(realpath "${1:-$(pwd)}")"

# parent_folder_name to move the crate to. Use "rust" or 2nd argument.
parent_folder_name="${2:-rust}"

echo "Creating workspace in $path_to_main_repo"

path_to_root_toml="${path_to_main_repo}/Cargo.toml"

# Check is have the Cargo.toml file
if [[ ! -f ${path_to_root_toml} ]]; then
  echo "Cargo.toml not found. Refusing to evaluate."
  exit 1
fi

# Is have a "[workspace]" section
if grep -q '\[workspace\]' "${path_to_root_toml}"; then
  echo "Workspace already exists. Refusing to evaluate."
  exit 1
fi

# Get the name of the crate from Cargo.toml
crate_name="$(grep '^name\s*=' "${path_to_root_toml}" | sed 's/^name\s*=\s*"\|"$//g')"

echo "Name of the crate is: '${crate_name}'"

new_folder_for_crate="${path_to_main_repo}/${parent_folder_name}/${crate_name}"
mkdir --parents "${new_folder_for_crate}"

echo "Moving crate to ${new_folder_for_crate}"

# Move with "git mv" these items to the new folder:
# - src folder with content
# - Cargo.toml file

# shellcheck disable=SC2046
git mv $(git ls-files --directory src Cargo.toml | sed 's/\/.*//g' | sort | uniq | grep --invert-match '^\.gitignore$') "${new_folder_for_crate}"

members_expression="${parent_folder_name}/*"

cat <<EOF >"${path_to_root_toml}"
[workspace]
resolver = "2"

members = [
    "${members_expression}",
]
EOF

git add "${path_to_root_toml}"
