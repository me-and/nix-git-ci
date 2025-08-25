{
  pkgs,
  lib,
  runCommandLocal,
  runtimeShell,
  gitMinimal,
  nix-prefetch-git,
  jq,
  common-updater-scripts,
  path,
}:
let
  env = {
    inherit runtimeShell;
    branches = lib.escapeShellArgs (builtins.attrNames (import ./versions.nix { inherit pkgs lib; }));
    runtimeDeps = lib.makeBinPath [
      nix-prefetch-git
      gitMinimal
      jq
      common-updater-scripts
    ];
    nixPath = lib.escapeShellArg path;
    owner = "gitster";
    repo = "git";
    localSrcName = "git-src";
  };
in
runCommandLocal "nix-git-ci-updater" env ''
  mkdir -p "$out"/bin "$out"/libexec
  cp ${./prep-git-src.sh} "$out"/libexec/prep-git-src.sh
  cp ${./update.sh} "$out"/bin/update.sh

  substituteAllInPlace "$out"/libexec/prep-git-src.sh
  substituteAllInPlace "$out"/bin/update.sh
''
