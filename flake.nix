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
        attrSetLen = s: builtins.length (builtins.attrNames s);
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
                # Excluding the fetchTags test per
                # https://github.com/NixOS/nixpkgs/issues/412967
                filterAttrs (n: v: (isDerivation v) && (n != "fetchTags")) pkgs.tests.fetchgit
              );
            allChecks = packageChecks // fetchgitChecks;
          in
          # Ensure we don't have any overlappying names that mean the //
          # operator has dropped some checks.
          assert attrSetLen allChecks == attrSetLen packageChecks + attrSetLen fetchgitChecks;
          allChecks;

        apps.updateScript = {
          type = "app";
          program = "${self.packages."${system}".git.passthru.updateScript}";
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
