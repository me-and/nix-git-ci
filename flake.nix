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

                  # Nixpkgs builds Git from a release tarball, which ships a
                  # generated `configure`; that picks up curl-config via the
                  # `ac_cv_prog_CURL_CONFIG` configure flag Nixpkgs sets.  We
                  # build from the Git repository, which has no `configure`, so
                  # the Makefile instead looks for a bare `curl-config` on
                  # PATH.  Since Nixpkgs enabled strictDeps for Git, curl's dev
                  # output is no longer on PATH, so that lookup fails and
                  # linking against libcurl breaks.
                  #
                  # Putting curl's dev output in nativeBuildInputs fixes this
                  # for both build styles, so it's a better fix than setting
                  # CURL_CONFIG, and is what Nixpkgs should adopt.
                  # https://github.com/NixOS/nixpkgs/commit/a3c24cd21
                  addCurlConfigToPath = prevAttrs: {
                    nativeBuildInputs = prevAttrs.nativeBuildInputs or [ ] ++ [ (lib.getDev pkgs.curl) ];
                  };

                  # Nixpkgs sets SHELL_PATH to stdenv.shell, which is bash
                  # under its own name.  Upstream's default is /bin/sh, and
                  # bash only enters POSIX mode when invoked as `sh`, so
                  # Nixpkgs runs the test suite in a mode upstream almost never
                  # exercises.  That's a real difference in behaviour rather
                  # than a cosmetic one: t1017 (new since v2.55.0 via
                  # ps/cat-file-remote-object-info) has an unquoted redirection
                  # target,
                  #
                  #     echo_without_newline "$hello_content" > $daemon_parent/hello
                  #
                  # whose value contains the trash directory path, which always
                  # has a space in it.  POSIX only requires field splitting of
                  # a redirection word in interactive shells, so bash-as-`sh`
                  # expands it to the single intended path, while bash under
                  # its own name splits it and fails with "ambiguous
                  # redirect", taking out 13 of t1017's 21 tests.
                  #
                  # (This is not about the shebangs: t/run-test.sh runs each
                  # test under TEST_SHELL_PATH, which defaults to SHELL_PATH.)
                  #
                  # Point SHELL_PATH at the same shell's `sh` entrypoint, which
                  # matches upstream's default behaviour.  Nixpkgs should adopt
                  # this too.  Note stdenv.shell is runtimeShellPackage's bash,
                  # not stdenv.shellPackage's -- the latter is interactive bash
                  # on Linux, and pulling that in would be a change of shell as
                  # well as of argv[0].
                  useShAsShellPath =
                    prevAttrs:
                    lib.optionalAttrs (pkgs.stdenv.buildPlatform == pkgs.stdenv.hostPlatform) {
                      makeFlags =
                        builtins.filter (flag: !(lib.isString flag && lib.hasPrefix "SHELL_PATH=" flag))
                          prevAttrs.makeFlags or [ ]
                        ++ [ "SHELL_PATH=${lib.getExe' pkgs.runtimeShellPackage "sh"}" ];
                    };

                  # Disable patching test shebangs.  As proven by the
                  # `useShAsShellPath` override, these shebangs aren't actually
                  # used.  This should be merged into Nixpkgs in the near
                  # future, but it doesn't warrant a PR on its own.
                  dontPatchTestShebangs = prevAttrs: {
                    postPatch = builtins.replaceStrings [ "patchShebangs t/*.sh" ] [ "" ] prevAttrs.postPatch;
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

                removeUnnecessaryRustPatch = prevAttrs: {
                  patches = builtins.filter (
                    p: builtins.baseNameOf p != "osxkeychain-link-rust_lib.patch"
                  ) prevAttrs.patches;
                };

                # The precompose_utf8 flex array fix is merged upstream as
                # ih/precompose-flex-array, so the Nixpkgs patch no longer
                # applies.  Drop it for branches that already have the fix;
                # Nixpkgs should drop it when it takes the release containing
                # the merge.
                removeAppliedPrecomposePatch = prevAttrs: {
                  patches = builtins.filter (
                    p: p.name or "" != "darwin-unicode-filename-fix.patch"
                  ) prevAttrs.patches;
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
                  attrOverrides = [
                    respectRustAfterDefaultOn
                    removeUnnecessaryRustPatch
                    removeAppliedPrecomposePatch
                  ];
                };
                gitNext = patchGit "next" gitNext {
                  attrOverrides = [
                    respectRustAfterDefaultOn
                    removeUnnecessaryRustPatch
                    removeAppliedPrecomposePatch
                  ];
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
