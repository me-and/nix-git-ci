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
  doInstallCheck ? null,
}:
let
  git' = if doInstallCheck != null then git.override { inherit doInstallCheck; } else git;
in
git'.overrideAttrs (
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
          jq
          common-updater-scripts
        ];
      in
      writeShellScript "update-git.sh" ''
        set -euo pipefail

        set_remote_ref () {
            if [[ -v remote_ref ]]; then
                echo 'unexpected arguments' >&2
                exit 64 # EX_USAGE
            fi
            remote_ref="$1"
        }

        commit=
        url=https://github.com/${owner}/${repo}
        while (( $# > 0 )); do
            case "$1" in
            -c)   commit=YesPlease
                  shift
                  ;;
            -u)   url="$2"
                  shift 2
                  ;;
            -c*|-u*)
                  set -- "-''${1: 1:1}" "-''${1: 2}" "''${@: 2}"
                  ;;
            --)   set_remote_ref "$2"
                  shift 2
                  ;;
            *)    set_remote_ref "$1"
                  shift
                  ;;
            esac
        done

        if [[ ! -v remote_ref ]]; then
            remote_ref=refs/heads/next
        fi

        export PATH=${lib.makeBinPath runtimeReqs}:"$PATH"
        export NIX_PATH=nixpkgs=${lib.escapeShellArg path}
        export NIX_PREFETCH_GIT_CHECKOUT_HOOK=${lib.escapeShellArg preFetchHookCmd}

        cmd="$(nix-prefetch-git --url "$url" --rev "$remote_ref" --deepClone --fetch-submodules --name ${localSrcName} | jq -r '@sh "rev=\(.rev) hash=\(.hash) store_path=\(.path)"')"
        eval "$cmd"

        version="$(<"$store_path"/version)"

        cmd="$(update-source-version git "$version" "$hash" --file=git.nix --rev="$rev" --print-changes | jq -r '.[] | @sh "old_version=\(.oldVersion) new_version=\(.newVersion)"')"

        # Only anything to commit if cmd has contents, otherwise it's
        # indicating the version hasn't changed.
        if [[ "$commit" && "$cmd" ]]; then
            eval "$cmd"
            git commit -m "git: $old_version -> $new_version" -- git.nix
        fi
      '';
  in
  {
    src = fetchFromGitHub {
      inherit owner repo;
      name = localSrcName;
      rev = "ccaa498523280e6ffb126e4837a8963c255233f3";
      fetchSubmodules = false;
      deepClone = true;
      leaveDotGit = false;
      preFetch = "export NIX_PREFETCH_GIT_CHECKOUT_HOOK=${lib.escapeShellArg preFetchHookCmd}";
      hash = "sha256-cY9hY/G8/2Weg262oMcretVDfTUNLBuJjFWZhRdDl7o=";
    };

    version = "2.49.0.1101.gccaa498523";

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

    nativeBuildInputs = (prevAttrs.nativeBuildInputs or []) ++ [autoconf];
    preConfigure = ''
      # Make the configure script using the same flags as for normal build
      # steps.
      local flagsArray=(
          ''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}}
          SHELL="$SHELL"
      )
      concatTo flagsArray makeFlags makeFlagsArray buildFlags buildFlagsArray
      make "''${flagsArray[@]}" configure
    '' + (prevAttrs.preConfigure or "");
  }
)
