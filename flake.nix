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
    {
      passthru.self = self;
      passthru.inputs = inputs;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs-unstable = import nixpkgs-unstable { inherit system; };
        lib = pkgs-unstable.lib;

        channels =
          if lib.hasSuffix "-linux" system then
            [
              "nixpkgs-unstable"
              "nixos-unstable"
              "nixos-stable"
            ]
          else if lib.hasSuffix "-darwin" system then
            [
              "nixpkgs-unstable"
              "nixpkgs-stable-darwin"
            ]
          else
            throw "Unexpected system type ${system}";

        channelToPkgs = channel: import (builtins.getAttr channel inputs) { inherit system; };

        # Combination of lib.attrsets.mergeAttrsList and
        # lib.attrsets.unionOfDisjoint: merge an arbitrary sized list of
        # attrsets, where any attr that is defined in multiple sets will throw
        # an error.
        mergeDisjoint = lib.foldl lib.attrsets.unionOfDisjoint { };
      in
      rec {
        packages =
          let
            channelToPackages =
              channel:
              lib.mapAttrs' (n: v: lib.nameValuePair "${n}-${channel}" v) (
                import ./. {
                  inherit channel;
                  pkgs = channelToPkgs channel;
                }
              );
            allPackages = mergeDisjoint (map channelToPackages channels);
          in
          allPackages // { default = allPackages.default-nixpkgs-unstable; };

        checks =
          let
            channelToChecks =
              channel:
              lib.mapAttrs' (n: v: lib.nameValuePair "${n}-${channel}" v) (
                import ./checks.nix {
                  inherit channel;
                  pkgs = channelToPkgs channel;
                }
              );
          in
          mergeDisjoint (map channelToChecks channels);

        apps.updateScript = {
          type = "app";
          program = "${packages.default.passthru.updateScript}";
        };

        formatter = pkgs-unstable.nixfmt-tree;
      }
    );
}
