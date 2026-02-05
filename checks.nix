{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  channelName,
  updateScript,
}:
let
  gitPackages = import ./. {
    inherit
      pkgs
      lib
      channelName
      updateScript
      ;
  };

  packageChecks = lib.mapAttrs (_: v: v.overrideAttrs { doInstallCheck = true; }) gitPackages;

  versionData = import ./versions.nix {
    inherit pkgs lib channelName;
  };

  fetchgitCheckFn =
    versionData:
    let
      git = gitPackages."git-${versionData.safeName}";
      gitMinimal = gitPackages."gitMinimal-${versionData.safeName}";
      git-lfs = pkgs.git-lfs.override { inherit git; };
      fetchgit = pkgs.fetchgit.override {
        inherit git-lfs;
        # fetchgit is defined in all-packages.nix with git as
        # gitMinimal.
        git = gitMinimal;
      };

      # TODO raise this bug: the underlying test doesn't work in pure
      # evaluation mode.  Try `nix build nixpkgs#tests.fetchgit.withGitConfig`.
      brokenTests = [ "withGitConfig" ];
      baseFetchgitChecks = lib.filterAttrs (
        n: v: !(builtins.elem n brokenTests) && lib.isDerivation v
      ) pkgs.tests.fetchgit;
    in
    lib.mapAttrs' (
      n: v: lib.nameValuePair "${n}-${versionData.safeName}" (v.override { inherit fetchgit; })
    ) baseFetchgitChecks;

  fetchgitChecks = lib.mergeAttrsList (
    lib.attrsets.mapCartesianProduct ({ versionData }: fetchgitCheckFn versionData) {
      versionData = builtins.attrValues versionData;
    }
  );
in
lib.attrsets.unionOfDisjoint packageChecks fetchgitChecks
