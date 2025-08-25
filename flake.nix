{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    nixos-unstable.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    nixos-stable.url = "github:NixOS/nixpkgs?ref=nixos-25.05";
    nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs?ref=nixpkgs-25.05-darwin";
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs-unstable,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        channelNames =
          let
            isType = type: (builtins.match ".*-${type}" system) == [ ];
          in
          if isType "linux" then
            [
              "nixpkgs-unstable"
              "nixos-unstable"
              "nixos-stable"
            ]
          else if isType "darwin" then
            [
              "nixpkgs-unstable"
              "nixpkgs-stable-darwin"
            ]
          else
            throw "Unexpected system type ${system}";
        topChannelName = builtins.head channelNames;

        channelToPkgs = channelName: import (builtins.getAttr channelName inputs) { inherit system; };

        pkgs = channelToPkgs topChannelName;
        inherit (pkgs) lib;

        # Combination of lib.attrsets.mergeAttrsList and
        # lib.attrsets.unionOfDisjoint: merge an arbitrary sized list of
        # attrsets, where any attr that is defined in multiple sets will throw
        # an error.
        mergeDisjoint = lib.foldl lib.attrsets.unionOfDisjoint { };
      in
      rec {
        packages =
          let
            channelToGitPackages =
              channelName:
              lib.mapAttrs' (n: v: lib.nameValuePair "${n}-${channelName}" v) (
                import ./. {
                  inherit channelName;
                  pkgs = channelToPkgs channelName;
                  updateScript = packages."updateScript-${channelName}";
                }
              );
            allGitPackages = mergeDisjoint (map channelToGitPackages channelNames);

            channelToUpdateScript = channelName: (channelToPkgs channelName).callPackage ./updater.nix { };

            updateScriptPackages = lib.listToAttrs (
              map (n: lib.nameValuePair "updateScript-${n}" (channelToUpdateScript n)) channelNames
            );
          in
          mergeDisjoint [
            allGitPackages
            updateScriptPackages
            { default = allGitPackages."default-${topChannelName}"; }
          ];

        checks =
          let
            channelToChecks =
              channelName:
              lib.mapAttrs' (n: v: lib.nameValuePair "${n}-${channelName}" v) (
                import ./checks.nix {
                  inherit channelName;
                  pkgs = channelToPkgs channelName;
                  updateScript = packages."updateScript-${channelName}";
                }
              );
          in
          mergeDisjoint (map channelToChecks channelNames);

        apps.updateScript = {
          type = "app";
          program = "${packages."updateScript-${topChannelName}"}/bin/update.sh";
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
