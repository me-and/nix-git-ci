{
  pkgs ? import <nixpkgs> { },
  channel ? null,
}:
let
  inherit (pkgs) lib;

  makeGitFrom = git: branch: pkgs.callPackage ./git.nix { inherit git branch; };

  gitFlavours = import ./packagenames.nix;

  versionData = import ./versions.nix { inherit lib channel; };

  branches = builtins.attrNames versionData;

  allPackages = lib.attrsets.mergeAttrsList (
    lib.attrsets.mapCartesianProduct
      (
        { flavour, branch }:
        {
          "${flavour}-${builtins.replaceStrings [ "." ] [ "_" ] branch}" =
            makeGitFrom (builtins.getAttr flavour pkgs) branch;
        }
      )
      {
        flavour = gitFlavours;
        branch = branches;
      }
  );
in
allPackages // { default = allPackages.git-master; }
