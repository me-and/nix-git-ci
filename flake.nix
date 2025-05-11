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
      in
      {
        packages = (import ./. { inherit pkgs; }) // {
          default = self.packages."${system}".git;
        };

        # TODO Also run the fetchgit tests and similar with the new versions of
        # the Git package.
        checks = mapAttrs (name: pkg: pkg.override { doInstallCheck = true; }) self.packages."${system}";

        apps.updateScript = {
          type = "app";
          program = "${self.packages."${system}".git.passthru.updateScript}";
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
