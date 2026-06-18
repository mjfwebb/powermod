#!/usr/bin/env bash
# install.sh - install or update powermod without cloning the repo:
#
#   curl -fsSL https://raw.githubusercontent.com/mjfwebb/powermod/main/install.sh | bash
#
# Re-running the same line updates the installed copy in place. powermod runs
# as your user (the custom levels re-exec themselves under sudo when applied),
# so installing needs no root.
#
# Overrides: POWERMOD_BIN_DIR for the install dir (default ~/.local/bin),
# POWERMOD_RAW_URL to fetch from a fork or branch.
set -euo pipefail

raw_url=${POWERMOD_RAW_URL:-https://raw.githubusercontent.com/mjfwebb/powermod/main}
bin_dir=${POWERMOD_BIN_DIR:-$HOME/.local/bin}

command -v curl >/dev/null || { echo "install.sh: curl is required" >&2; exit 1; }

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

# Fetch to a temp file and move into place only after the download succeeded
# and looks sane, so a failed fetch never clobbers a working install.
curl -fsSL "$raw_url/powermod" -o "$tmp_dir/powermod"
head -n1 "$tmp_dir/powermod" | grep -q '^#!' ||
  { echo "install.sh: $raw_url/powermod does not look like a script, not installing" >&2; exit 1; }

# The script carries its version as a VERSION= line; read it from a file
# rather than executing it. Empty for pre-versioning installs.
script_version() { sed -n 's/^VERSION=//p' "$1" 2>/dev/null | head -n1; }

target=$bin_dir/powermod
new_ver=$(script_version "$tmp_dir/powermod")
if [[ -e $target ]] && cmp -s "$tmp_dir/powermod" "$target"; then
  echo "powermod already up to date: $target${new_ver:+ ($new_ver)}"
else
  verb=installed; old_ver=""
  [[ -e $target ]] && { verb=updated; old_ver=$(script_version "$target"); }
  install -Dm755 "$tmp_dir/powermod" "$target"
  case $verb in
    updated)   echo "updated $target (${old_ver:-unversioned} -> ${new_ver:-unversioned})";;
    installed) echo "installed $target${new_ver:+ ($new_ver)}";;
  esac
fi

case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) echo "note: $bin_dir is not on your PATH" >&2 ;;
esac
