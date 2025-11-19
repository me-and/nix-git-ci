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
in
packageChecks
