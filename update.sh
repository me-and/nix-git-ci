#!@runtimeShell@

set -euo pipefail

help () {
    cat <<'EOF'
update-git.sh [-c] [-u <url>] [-l <path>] [--] [<branch>...]

Update the version information for the various Git branches built in the
nix-git-ci repository.

-h, --help:
    Print this help message.

-c, --commit:
    Create commits for any updated branches.

-u <url>, --url=<url>:
    Clone from the specified Git repository rather than the default
    `https://github.com/@owner@/@repo@`.

-l <path>, --local=<path>:
    When cloning the Git repository, include the specified path using the
    `--reference` argument to `git clone`.  This can speed up the cloning
    process by reducing the number of objects Git needs to download from the
    remote repository.

<branch>:
    When branches are specified on the command line, only the given branches
    will be updated.  If no branches are specified, all branches in
    versions.nix will be updated.
EOF
}

commit=
url=https://github.com/@owner@/@repo@
branches=()
explicit_branches=
local_ref_args=()
while (( $# > 0 )); do
    case "$1" in
    -h|--help)
	help
	exit 0
	;;
    -c|--commit)
	commit=YesPlease
	shift
	;;
    -u|--url)
	url="$2"
	shift 2
	;;
    -l|--local)
	local_ref_args+=(--reference "$2")
	shift 2
	;;
    -c*|-u*|-l*)
	set -- "-''${1: 1:1}" "-''${1: 2}" "''${@: 2}"
	;;
    --url=*|--local=*)
	set -- "''${1%%=*}" "''${1#*=}" "''${@: 2}"
	;;
    --) shift
	branches+=("$@")
	explicit_branches=yes
	break
	;;
    *)  branches+=("$1")
	explicit_branches=yes
	shift
	;;
    esac
done

if [[ -z "$explicit_branches" ]]; then
    branches=(@branches@)
fi

export PATH=@runtimeDeps@:"$PATH"
export NIX_PATH=nixpkgs=@nixPath@
export NIX_PREFETCH_GIT_CHECKOUT_HOOK='@out@/libexec/prep-git-src.sh "$dir"'

if (( ${#branches[*]} > 1 )) || (( ${#local_ref_args[*]} > 0 )); then
    # Create a local mirror of the remote repository, so we only need
    # to get the remote repository once, and/or we can make use of
    # local copies of the repository.
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT
    git clone --mirror "${local_ref_args[@]}" "$url" "$tmp_dir"
    url="$tmp_dir"
fi

for branch in "${branches[@]}"; do
    if [[ "$branch" = *=* ]]; then
	# Allow specifying, say, master=3589aaa to specify what
	# commit should be used for the branch.
	rev="${branch#*=}"
	branch="${branch%%=*}"
    else
	rev="refs/heads/$branch"
    fi

    cmd="$(nix-prefetch-git --url "$url" --rev "$rev" --deepClone --name @localSrcName@ | jq -r '@sh "rev=\(.rev) hash=\(.hash) store_path=\(.path)"')"
    eval "$cmd"

    version="$(<"$store_path"/version)"

    cmd="$(update-source-version git-"${branch//./_}" "$version" "$hash" --file=versions.nix --rev="$rev" --print-changes | jq -r '.[] | @sh "old_version=\(.oldVersion) new_version=\(.newVersion)"')"

    # Only anything to commit if cmd has contents, otherwise it's
    # indicating the version hasn't changed.
    if [[ "$commit" && "$cmd" ]]; then
	eval "$cmd"
	git commit -m "git $branch: $old_version -> $new_version" -- versions.nix
    fi
done
