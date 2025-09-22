{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  updateScript ? pkgs.callPackage ./updater.nix { },

  # Special value "all" for channelName means to set things up to provide all
  # possible packages, even if we know they won't build successfully.
  channelName ? "all",
}:
let
  gitPackageNameData = import ./packagenames.nix {
    inherit pkgs lib channelName;
  };
  topGitPackageName = builtins.head (
    lib.sortOn (n: gitPackageNameData."${n}".priority) (builtins.attrNames gitPackageNameData)
  );
  gitPackageNames = builtins.attrNames gitPackageNameData;

  versionData = import ./versions.nix {
    inherit pkgs lib channelName;
  };
  topVersionData = builtins.head (lib.sortOn (v: v.priority) (builtins.attrValues versionData));

  makeGitFrom =
    baseGit: versionData: pkgs.callPackage ./git.nix { inherit baseGit versionData updateScript; };

  allPackages = lib.attrsets.mergeAttrsList (
    lib.attrsets.mapCartesianProduct
      (
        { packageName, versionData }:
        {
          "${packageName}-${versionData.safeName}" =
            makeGitFrom (builtins.getAttr packageName pkgs) versionData;
        }
      )
      {
        packageName = gitPackageNames;
        versionData = builtins.attrValues versionData;
      }
  );
in
allPackages // { default = allPackages."${topGitPackageName}-${topVersionData.safeName}"; }
