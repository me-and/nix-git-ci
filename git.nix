{
  lib,
  git,
  fetchFromGitHub,
  writeShellScript,
  gitMinimal,
  nix-prefetch-git,
  common-updater-scripts,
  path,
  jq,
  autoconf,
  gnupatch,
  stdenv,
  doInstallCheck ? null,
  branch ? "next",
}:
let
  git' = if doInstallCheck != null then git.override { inherit doInstallCheck; } else git;

  # Note this must not filter the branch names, since the update script should
  # update all the branches regardless of what might be built for this system /
  # branch / nixpkgs combination.
  versionData = import ./versions.nix { };
  inherit (versionData."${branch}") rev hash version;
  extraOverride = versionData."${branch}".extraOverride or { };

  git'' = git'.overrideAttrs (
    prevAttrs:
    let
      owner = "gitster";
      repo = "git";
      localSrcName = "git-src";

      preFetchScript = writeShellScript "prep-git-src.sh" ''
        # Send stdout to stderr so our commands don't change expected nix output
        exec >&2
        set -euo pipefail
        shopt -s extglob
        export PATH=${gitMinimal}/bin:"$PATH"
        cd "$1"

        # Ordering matters here: the second `make` command will create a
        # `version` file in the root of the repository containing the git-gui
        # version, but we need that file to contain the Git version.
        make GIT-VERSION-FILE
        make -C git-gui TARDIR="$PWD" dist-version

        version_file_contents="$(<GIT-VERSION-FILE)"
        echo "''${version_file_contents##GIT_VERSION*( )=*( )}" >version

        version_file_contents="$(<git-gui/GIT-VERSION-FILE)"
        echo "''${version_file_contents##GITGUI_VERSION*( )=*( )}" >git-gui/version
      '';

      preFetchHookCmd = "${preFetchScript} \"$dir\"";

      updateScript =
        let
          runtimeReqs = [
            nix-prefetch-git
            gitMinimal
            jq
            common-updater-scripts
          ];
        in
        writeShellScript "update-git.sh" ''
          set -euo pipefail

          help () {
              cat <<'EOF'
          update-git.sh [-c] [-u <url>] [-l <path>] [--] [<branch>...]

          Update the version information for the various Git branches built in
          the nix-git-ci repository.

          -h, --help:
              Print this help message.

          -c, --commit:
              Create commits for any updated branches.

          -u <url>, --url=<url>:
              Clone from the specified Git repository rather than the default
              `https://github.com/${owner}/${repo}`.

          -l <path>, --local=<path>:
              When cloning the Git repository, include the specified path using
              the `--reference` argument to `git clone`.  This can speed up the
              cloning process by reducing the number of objects Git needs to
              download from the remote repository.

          <branch>:
              When branches are specified on the command line, only the given
              branches will be updated.  If no branches are specified, all
              branches in versions.nix will be updated.
          EOF
          }

          commit=
          url=https://github.com/${owner}/${repo}
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
              branches=(${lib.escapeShellArgs (builtins.attrNames versionData)})
          fi

          export PATH=${lib.makeBinPath runtimeReqs}:"$PATH"
          export NIX_PATH=nixpkgs=${lib.escapeShellArg path}
          export NIX_PREFETCH_GIT_CHECKOUT_HOOK=${lib.escapeShellArg preFetchHookCmd}

          if (( ''${#branches[*]} > 1 )) || (( ''${#local_ref_args[*]} > 0 )); then
              # Create a local mirror of the remote repository, so we only need
              # to get the remote repository once, and/or we can make use of
              # local copies of the repository.
              tmp_dir="$(mktemp -d)"
              trap 'rm -rf "$tmp_dir"' EXIT
              git clone --mirror "''${local_ref_args[@]}" "$url" "$tmp_dir"
              url="$tmp_dir"
          fi

          for branch in "''${branches[@]}"; do
              if [[ "$branch" = *=* ]]; then
                  # Allow specifying, say, master=3589aaa to specify what
                  # commit should be used for the branch.
                  rev="''${branch#*=}"
                  branch="''${branch%%=*}"
              else
                  rev="refs/heads/$branch"
              fi

              cmd="$(nix-prefetch-git --url "$url" --rev "$rev" --deepClone --name ${localSrcName} | jq -r '@sh "rev=\(.rev) hash=\(.hash) store_path=\(.path)"')"
              eval "$cmd"

              version="$(<"$store_path"/version)"

              cmd="$(update-source-version git-"''${branch//./_}" "$version" "$hash" --file=versions.nix --rev="$rev" --print-changes | jq -r '.[] | @sh "old_version=\(.oldVersion) new_version=\(.newVersion)"')"

              # Only anything to commit if cmd has contents, otherwise it's
              # indicating the version hasn't changed.
              if [[ "$commit" && "$cmd" ]]; then
                  eval "$cmd"
                  git commit -m "git $branch: $old_version -> $new_version" -- versions.nix
              fi
          done
        '';
    in
    {
      inherit version;

      src = fetchFromGitHub {
        inherit
          owner
          repo
          rev
          hash
          ;
        name = localSrcName;
        fetchSubmodules = false;
        deepClone = true;
        leaveDotGit = false;
        preFetch = "export NIX_PREFETCH_GIT_CHECKOUT_HOOK=${lib.escapeShellArg preFetchHookCmd}";
      };

      passthru = (prevAttrs.passthru or { }) // {
        inherit preFetchScript updateScript;
      };

      # Needed as of v2.49.0-392-gfe35ce2ef8(contrib/completion: install Bash
      # completion, 2025-04-22)
      postInstall =
        builtins.replaceStrings
          [
            "\nln -s $out/share/git/contrib/completion/git-completion.bash $out/share/bash-completion/completions/git\n"
          ]
          [ "\n" ]
          prevAttrs.postInstall;

      # These *shouldn't* be necessary, but it looks like they're long-standing
      # failures that aren't being caught by the Darwin builds because the
      # mainline Darwin builds don't run the tests in the first place.
      preInstallCheck =
        (prevAttrs.preInstallCheck or "")
        + lib.optionalString stdenv.hostPlatform.isDarwin ''
          ${gnupatch}/bin/patch -p1 <${./t3900-mac.diff}
          disable_test t7900-maintenance 'start without GIT_TEST_MAINT_SCHEDULER'
        '';

      preConfigure =
        ''
          # Use a subshell for the extra preconfigure steps to avoid changing the
          # environment used for the rest of the Git build.
          (
              # Make the configure script using the same flags as for normal
              # build steps.
              local flagsArray=(
                  ''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}}
                  SHELL="$SHELL"
              )
              export PATH="${autoconf}/bin''${PATH:+:$PATH}"
              concatTo flagsArray makeFlags makeFlagsArray buildFlags buildFlagsArray
              make "''${flagsArray[@]}" configure
          )
        ''
        + (prevAttrs.preConfigure or "");
    }
  );
  git''' = git''.overrideAttrs extraOverride;
in
git'''
