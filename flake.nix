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
        inherit (nixpkgs.lib)
          concatMapAttrs
          mapAttrs'
          nameValuePair
          filterAttrs
          ;
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = (import ./. { inherit pkgs; }) // {
          default = self.packages."${system}".git;
        };

        # For each package, build and reference everything in the
        # package.passthru.tests attrset.
        checks = concatMapAttrs (
          pkgName: pkg:
          mapAttrs' (testName: testDrv: nameValuePair (pkgName + " " + testName) testDrv) (
            removeAttrs pkg.passthru.tests [
              "override"
              "overrideDerivation"
            ]
          )
        ) self.packages."${system}";

        apps.updateScript = {
          type = "app";
          program = "${self.packages."${system}".git.passthru.updateScript}";
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
