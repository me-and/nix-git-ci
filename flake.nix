{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    {
      passthru.self = self;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        packages = import ./. { inherit pkgs; };

        checks = import ./checks.nix { inherit pkgs; };

        apps.updateScript = {
          type = "app";
          program = "${packages.default.passthru.updateScript}";
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
