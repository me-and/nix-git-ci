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
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        inherit (nixpkgs.lib) mapAttrs;
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
      in
      {
        packages = (import ./. { inherit pkgs; }) // {
          default = self.packages."${system}".git;
        };

        checks =
          let
            packageChecks = mapAttrs (_: v: v.override { doInstallCheck = true; }) (
              removeAttrs self.packages."${system}" [ "default" ]
            );
            fetchgitChecks =
              let
                inherit (self.packages."${system}") git;
                git-lfs = pkgs.git-lfs.override { inherit git; };
                fetchgit = pkgs.fetchgit.override { inherit git git-lfs; };
              in
              mapAttrs (_: v: v.override { inherit fetchgit; }) (
                lib.filterAttrs (_: v: lib.isDerivation v) pkgs.tests.fetchgit
              );
          in
          packageChecks // fetchgitChecks;

        apps.updateScript = {
          type = "app";
          program = "${self.packages."${system}".git.passthru.updateScript}";
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
