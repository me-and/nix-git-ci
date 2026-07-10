{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";

    gitMain = {
      url = "github:gitster/git";
      flake = false;
    };
    gitNext = {
      url = "github:gitster/git?ref=next";
      flake = false;
    };
    gitMaint = {
      url = "github:gitster/git?ref=maint-2.54";
      flake = false;
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      gitMain,
      gitNext,
      gitMaint,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        inherit (nixpkgs) lib;
        pkgs = import nixpkgs { inherit system; };
      in
      {
        legacyPackages =
          let
            applyOverrides = nixpkgs.lib.foldl' (drv': override: drv'.override override);
            applyAttrOverrides = nixpkgs.lib.foldl' (drv': override: drv'.overrideAttrs override);

            patchGit =
              name: src:
              {
                overrides ? [ ],
                attrOverrides ? [ ],
              }:
              git:
              let
                defaultAttrOverrides = builtins.attrValues {
                  setSrc = { inherit src; };

                  # Include the branch name and revision in the derivation name.
                  addName = prevAttrs: { pname = "${prevAttrs.pname}-${name}@${src.shortRev}"; };

                  # The passthru tests are either (a) just building the package
                  # as we already do, or (b) built using Nixpkgs' base Git
                  # package rather than the one we're creating, so aren't
                  # testing anything new.  Disable the lot of them.
                  #
                  # TODO: Fix things so we override the tests to use the
                  # versions of Git that we're building.  That should probably
                  # happen in Nixpkgs rather than here.
                  removeBuildbotTest = prevAttrs: {
                    passthru = prevAttrs.passthru // {
                      tests = { };
                    };
                  };

                  # Set the value of debug in the installCheckPhase environment.
                  # https://github.com/NixOS/nixpkgs/pull/537119#issuecomment-4939419503
                  noDebugTests = prevAttrs: {
                    installCheckFlags = prevAttrs.installCheckFlags or [ ] ++ [ "debug=" ];
                  };

                  # Disable t1517 because it's too unreliable.
                  # https://github.com/NixOS/nixpkgs/pull/537119
                  noT1517 = prevAttrs: {
                    preInstallCheck = prevAttrs.preInstallCheck or "" + ''
                      rm t/t1517-outside-repo.sh
                    '';
                  };
                };

                defaultOverride = {
                  doInstallCheck = true;
                };

                git' = applyAttrOverrides git (defaultAttrOverrides ++ attrOverrides);
                git'' = applyOverrides git' ([ defaultOverride ] ++ overrides);
              in
              git'';

            gitSourcePatchers =
              let
                respectRustAfterDefaultOn = prevAttrs: {
                  makeFlags =
                    let
                      parts = builtins.partition (s: s != "WITH_RUST=YesPlease") prevAttrs.makeFlags;
                      wantRust = builtins.length parts.wrong > 0;
                    in
                    parts.right ++ nixpkgs.lib.optional (!wantRust) "NO_RUST=YesPlease";
                };

                # Check the version in Nixpkgs matches the version in the Git
                # maintenance branch, to avoid Nixpkgs getting ahead/behind of
                # the Git maintenance branch I'm tracking.
                checkMaintVersion = finalAttrs: prevAttrs: {
                  passthru = prevAttrs.passthru // {
                    tests = lib.attrsets.unionOfDisjoint prevAttrs.passthru.tests {
                      maintVersionCheck =
                        let
                          nixpkgsGitVersion = lib.versions.majorMinor prevAttrs.version;
                        in
                        pkgs.runCommand "maint-version" { } ''
                          src_dir=${lib.escapeShellArg finalAttrs.src}
                          src_version="$("$src_dir"/GIT-VERSION-GEN "$src_dir" --format=@GIT_MAJOR_VERSION@.@GIT_MINOR_VERSION@)"

                          if [[ "$src_version" = ${lib.escapeShellArg nixpkgsGitVersion} ]]; then
                            touch "$out"
                          else
                            echo "git maintenance version mismatch"
                            echo "nixpkgs has "${lib.escapeShellArg nixpkgsGitVersion}
                            echo "git maintenance branch has $src_version"
                            echo "probably want to update the maintenance branch in flake.nix"
                            exit 78
                          fi >&2
                        '';
                    };
                  };
                };
              in
              {
                gitMain = patchGit "main" gitMain {
                  attrOverrides = [ respectRustAfterDefaultOn ];
                };
                gitNext = patchGit "next" gitNext {
                  attrOverrides = [ respectRustAfterDefaultOn ];
                };
                gitMaint = patchGit "maint" gitMaint { attrOverrides = [ checkMaintVersion ]; };
              };

            basePackages = {
              inherit (pkgs)
                gitMinimal
                git
                gitSVN
                gitFull
                ;
            };

            recurseForDerivations = s: s // { recurseForDerivations = true; };

            patcherToGitPackages = patcher: recurseForDerivations (builtins.mapAttrs (n: patcher) basePackages);
          in
          builtins.mapAttrs (n: patcherToGitPackages) gitSourcePatchers;

        packages = flake-utils.lib.flattenTree self.legacyPackages."${system}";

        checks = flake-utils.lib.flattenTree (
          builtins.mapAttrs (n: v: {
            package = v;
            tests = v.passthru.tests;
            recurseForDerivations = true;
          }) self.packages."${system}"
        );

        formatter = pkgs.nixfmt-tree;
      }
    );
}
