#!@runtimeShell@

# Send stdout to stderr so our commands don't change expected nix output
exec >&2
set -euo pipefail
shopt -s extglob
export PATH=@runtimeDeps@:"$PATH"
cd "$1"

# Ordering matters here: the second `make` command will create a `version`
# file in the root of the repository containing the git-gui version, but we
# need that file to contain the Git version.
make GIT-VERSION-FILE
make -C git-gui TARDIR="$PWD" dist-version

version_file_contents="$(<GIT-VERSION-FILE)"
echo "${version_file_contents##GIT_VERSION*( )=*( )}" >version

version_file_contents="$(<git-gui/GIT-VERSION-FILE)"
echo "${version_file_contents##GITGUI_VERSION*( )=*( )}" >git-gui/version

rm -rf .git
