{
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (pkgs.lib)
    mapAttrs
    mapAttrs'
    nameValuePair
    filterAttrs
    mergeAttrsList
    isDerivation
    ;
  inherit (pkgs.lib.attrsets) unionOfDisjoint;

  packages = import ./. { inherit pkgs; };

  packageChecks = mapAttrs (_: v: v.override { doInstallCheck = true; }) packages;

  versionData = import ./versions.nix;
  branches = builtins.attrNames versionData;

  fetchgitCheckFn =
    branch:
    let
      mungedBranch = builtins.replaceStrings [ "." ] [ "_" ] branch;
      git = packages."git-${mungedBranch}";
      gitMinimal = packages."gitMinimal-${mungedBranch}";
      git-lfs = pkgs.git-lfs.override { inherit git; };
      fetchgit = pkgs.fetchgit.override {
        inherit git-lfs;
        # fetchgit is defined in all-packages.nix with git as
        # gitMinimal.
        git = gitMinimal;
      };
    in
    mapAttrs' (n: v: nameValuePair "${n}-${mungedBranch}" (v.override { inherit fetchgit; })) (
      filterAttrs (n: v: isDerivation v && n != "fetchTags") pkgs.tests.fetchgit
    );
  fetchgitChecks = mergeAttrsList (builtins.map fetchgitCheckFn branches);
in
unionOfDisjoint packageChecks fetchgitChecks
