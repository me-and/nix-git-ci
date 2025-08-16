{
  pkgs ? import <nixpkgs> { },
  channel ? null,
}:
let
  inherit (pkgs) lib;

  makeGitFrom = git: branch: pkgs.callPackage ./git.nix { inherit git branch; };

  gitFlavours = import ./packagenames.nix;

  versionData = import ./versions.nix { inherit lib channel; };

  # Don't want to assume any particular version exists, so each version has a
  # priority and we just set the default package to whichever one comes out on
  # top.
  highestPriorityVersion = builtins.head (
    lib.sortOn (n: versionData."${n}".priority) (builtins.attrNames versionData)
  );

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
allPackages // { default = allPackages."git-${highestPriorityVersion}"; }
