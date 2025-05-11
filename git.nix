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
}:
git.overrideAttrs (
  prevAttrs:
  let
    owner = "gitster";
    repo = "git";
    localSrcName = "git-src";

    preFetchScript = writeShellScript "prep-git-src.sh" ''
      # Send stdout to stderr so our commands don't change expected nix output
      exec >&2
      set -euo pipefail
      export PATH=${gitMinimal}/bin:"$PATH"
      cd "$workdir"
      make GIT-VERSION-FILE
      make -C git-gui TARDIR="$PWD" dist-version
      . GIT-VERSION-FILE
      echo "$GIT_VERSION" >version
    '';

    preFetchHookCmd = "workdir=\"$dir\" ${preFetchScript}";

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

        if (( $# == 0 )); then
            remote_ref=refs/heads/next
        elif (( $# == 1 )); then
            remote_ref="$1"
        else
            echo 'unexpected arguments' >&2
            exit 64 # EX_USAGE
        fi

        export PATH=${lib.makeBinPath runtimeReqs}:"$PATH"
        export NIX_PATH=nixpkgs=${lib.escapeShellArg path}
        export NIX_PREFETCH_GIT_CHECKOUT_HOOK=${lib.escapeShellArg preFetchHookCmd}

        cmd="$(nix-prefetch-git --url https://github.com/${owner}/${repo} --rev "$remote_ref" --deepClone --fetch-submodules --name ${localSrcName} | jq -r '@sh "rev=\(.rev) hash=\(.hash) store_path=\(.path)"')"
        eval "$cmd"

        version="$(<"$store_path"/version)"

        update-source-version git "$version" "$hash" --file="$PWD"/git.nix --rev="$rev"
      '';
  in
  {
    src = fetchFromGitHub {
      inherit owner repo;
      name = localSrcName;
      rev = "ccaa498523280e6ffb126e4837a8963c255233f3";
      fetchSubmodules = true;
      deepClone = true;
      leaveDotGit = false;
      preFetch = "export NIX_PREFETCH_GIT_CHECKOUT_HOOK=${lib.escapeShellArg preFetchHookCmd}";
      hash = "sha256-J7vZxJ0bSkvWWOvtraOxHRDVqV+C5dFe77IP5sgR3DI=";
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
          "ln -s $out/share/git/contrib/completion/git-completion.bash $out/share/bash-completion/completions/git"
        ]
        [ "" ]
        prevAttrs.postInstall;
  }
)
