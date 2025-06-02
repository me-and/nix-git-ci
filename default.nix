{
  pkgs ? import <nixpkgs> { },
}:
let
  makeGitFrom = git: branch: pkgs.callPackage ./git.nix { inherit git branch; };

  gitFlavours = import ./packagenames.nix;

  versionData = import ./versions.nix;
  branches = builtins.attrNames versionData;

  allPackages = pkgs.lib.attrsets.mergeAttrsList (
    pkgs.lib.attrsets.mapCartesianProduct
      (
        { flavour, branch }:
        {
          "${flavour}-${branch}" = makeGitFrom (builtins.getAttr flavour pkgs) branch;
        }
      )
      {
        flavour = gitFlavours;
        branch = branches;
      }
  );
in
allPackages // { default = allPackages.git-master; }
