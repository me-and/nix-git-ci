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
        inherit (nixpkgs.lib) filterAttrs isDerivation mapAttrs;
        pkgs = import nixpkgs { inherit system; };
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
                inherit (self.packages."${system}") git gitMinimal;
                git-lfs = pkgs.git-lfs.override { inherit git; };
                fetchgit = pkgs.fetchgit.override {
                  inherit git-lfs;
                  # fetchgit is defined in all-packages.nix with git as
                  # gitMinimal.
                  git = gitMinimal;
                };
              in
              mapAttrs (_: v: v.override { inherit fetchgit; }) (
                filterAttrs (_: v: isDerivation v) pkgs.tests.fetchgit
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
