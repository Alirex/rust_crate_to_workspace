#!/usr/bin/env bash
# Convert a single Rust crate (git repository) into a cargo workspace.
#
# Usage: rust_crate_to_workspace.sh [path_to_repo] [folder_for_members]
#   path_to_repo        the crate's repository root (default: current directory)
#   folder_for_members  folder that gets the crate and holds future members (default: rust)
#
# Moves src/ and Cargo.toml to <folder>/<crate_name>/ with `git mv`, together with tests/, benches/, examples/ and
# build.rs when they exist. The file named by `readme =` is copied (the original stays, it is usually the repo README);
# without that key, the README Cargo would pick by itself. Relative `path` dependencies get a `../` per added level.
# Writes a workspace Cargo.toml and stages it. Everything else (Cargo.lock, .git*, CI, .cargo/, target/) stays.
# Refuses on a dirty git tree, a missing Cargo.toml, an existing [workspace], an existing target folder, or a
# readme/build/target path (`path = ...` of [lib], [[bin]], [[example]], [[test]], [[bench]]) that points outside
# the moved set.
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

# Manifest paths as "kind<TAB>value" lines (single-line string values only): `build` and `readme` of [package],
# `path` of [lib], [[bin]], [[example]], [[test]] and [[bench]].
manifest_paths="$(awk '
  /^[[:space:]]*\[/ {
    section = ""
    if ($0 ~ /^[[:space:]]*\[package\]/) { section = "package" }
    else if ($0 ~ /^[[:space:]]*\[(lib|\[bin|\[example|\[test|\[bench)\]+/) { section = "target" }
    next
  }
  section != "" && /^[[:space:]]*(build|readme|path)[[:space:]]*=[[:space:]]*"/ {
    key = $0
    sub(/^[[:space:]]*/, "", key)
    sub(/[[:space:]]*=.*$/, "", key)
    value = $0
    sub(/^[^"]*"/, "", value)
    sub(/".*$/, "", value)
    if ((section == "package" && key != "path") || (section == "target" && key == "path")) {
      print key "\t" value
    }
  }
' "${path_to_root_toml}")"

# The package-owned paths that move with Cargo.toml (when they exist).
moved_paths=""
for candidate in src tests benches examples build.rs; do
  if [[ -e ${candidate} ]]; then
    moved_paths="${moved_paths}${candidate} "
  fi
done

readme_to_copy=""
while IFS=$'\t' read -r kind value; do
  [[ -n ${kind} ]] || continue
  value="${value#./}"
  case "/${value}/" in
    */../*) die "${kind} = '${value}' points outside the crate." ;;
    *) ;;
  esac
  [[ ${value} != /* ]] || die "${kind} = '${value}' is an absolute path."
  top="${value%%/*}"
  case "${top}" in
    src | tests | benches | examples | build.rs) continue ;;
    *) ;;
  esac
  if [[ ${kind} == readme ]]; then
    readme_to_copy="${value}"
  else
    die "${kind} = '${value}' is not in src, tests, benches, examples or build.rs, so it would not move."
  fi
done <<<"${manifest_paths}"

mkdir -p "${new_folder_for_crate}"

echo "Moving crate to ${new_folder_for_crate}"
for moved in ${moved_paths}; do
  git mv -- "${moved}" "${new_folder_for_crate}/"
done
git mv -- Cargo.toml "${new_folder_for_crate}/"

# Without a `readme` key Cargo picks README.md, README.txt or README next to the manifest: copy that one too.
if ! awk '
  /^[[:space:]]*\[/ { in_package = ($0 ~ /^[[:space:]]*\[package\]/) }
  in_package && /^[[:space:]]*readme[[:space:]]*=/ { found = 1 }
  END { exit !found }
' "${new_folder_for_crate}/Cargo.toml"; then
  for candidate in README.md README.txt README; do
    if [[ -f ${candidate} ]]; then
      readme_to_copy="${candidate}"
      break
    fi
  done
fi

# Relative `path` dependencies now resolve from the member folder: prefix them with one `../` per added level.
depth_prefix=""
rest="${parent_folder_name%/}/${crate_name}"
while [[ -n ${rest} ]]; do
  depth_prefix="../${depth_prefix}"
  [[ ${rest} == */* ]] || break
  rest="${rest#*/}"
done
moved_toml="${new_folder_for_crate}/Cargo.toml"
awk -v prefix="${depth_prefix}" '
  /^[[:space:]]*\[/ {
    in_deps = ($0 ~ /^[[:space:]]*\[(.*\.)?(dependencies|dev-dependencies|dev_dependencies|build-dependencies|build_dependencies)(\..*)?\]/ \
      || $0 ~ /^[[:space:]]*\[patch\./)
  }
  in_deps && !/^[[:space:]]*\[/ {
    out = ""
    rest = $0
    while (match(rest, /(^|[[:space:]{,])path[[:space:]]*=[[:space:]]*"/)) {
      out = out substr(rest, 1, RSTART + RLENGTH - 1)
      rest = substr(rest, RSTART + RLENGTH)
      if (rest !~ /^\// && rest !~ /^[A-Za-z]:/) {
        out = out prefix
        rewritten++
      }
    }
    $0 = out rest
  }
  { print }
  END { if (rewritten) { printf "Rewrote %d path dependencies (prefix %s)\n", rewritten, prefix > "/dev/stderr" } }
' "${moved_toml}" >"${moved_toml}.tmp"
mv -- "${moved_toml}.tmp" "${moved_toml}"
git add -- "${moved_toml}"

if grep -Eq '^[[:space:]]*(include|exclude)[[:space:]]*=' "${moved_toml}"; then
  echo "Warning: Cargo.toml has include/exclude; its globs now match from ${parent_folder_name}/${crate_name}/, check them." >&2
fi

if [[ -n ${readme_to_copy} && -f ${readme_to_copy} ]]; then
  echo "Copying ${readme_to_copy} (readme) into the crate; the original stays"
  mkdir -p "$(dirname "${new_folder_for_crate}/${readme_to_copy}")"
  cp -- "${readme_to_copy}" "${new_folder_for_crate}/${readme_to_copy}"
  git add -- "${new_folder_for_crate}/${readme_to_copy}"
fi

cat >"${path_to_root_toml}" <<TOML
[workspace]
resolver = "2"

members = [
    "${parent_folder_name}/*",
]
TOML

git add -- "${path_to_root_toml}"
echo "Done. Review with 'git status' and commit."
