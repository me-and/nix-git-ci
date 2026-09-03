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

                # t1017, added by the ps/cat-file-remote-object-info topic (new
                # since v2.55.0, not yet in any release), has an unquoted
                # redirection target:
                #
                #     echo_without_newline "$hello_content" > $daemon_parent/hello
                #
                # $daemon_parent contains the trash directory path, which always
                # has a space in it.
                #
                # POSIX only requires field splitting of a redirection word in
                # interactive shells, so most shells -- including bash when it
                # is in POSIX mode -- expand this to the single intended path.
                # Bash invoked under its own name is *not* in POSIX mode, splits
                # the word in two, and fails with "ambiguous redirect".
                #
                # t/run-test.sh runs each test with TEST_SHELL_PATH, which
                # defaults to SHELL_PATH, so the patched shebangs are not what
                # decides this.  Upstream's SHELL_PATH default is /bin/sh, which
                # is POSIX mode even where /bin/sh is bash, so the bug is
                # invisible almost everywhere.  Nixpkgs sets SHELL_PATH to
                # stdenv.shell, i.e. .../bin/bash, so it runs the suite under
                # non-POSIX bash and trips over it.
                #
                # This is still an upstream bug rather than a Nixpkgs one:
                # config.mak.uname sets SHELL_PATH to a real bash on SunOS,
                # IRIX, UnixWare, SCO_SV and NonStop, so a bash test suite is a
                # configuration upstream supports.  Nothing on the list fixes it
                # as of writing, so it needs reporting there.  Quote the
                # redirection target here so we still get coverage of the rest
                # of the test in the meantime.
                fixT1017AmbiguousRedirect = prevAttrs: {
                  postPatch = prevAttrs.postPatch or "" + ''
                    substituteInPlace t/t1017-cat-file-remote-object-info.sh \
                      --replace-fail '> $daemon_parent/hello' '> "$daemon_parent/hello"'
                  '';
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
                    fixT1017AmbiguousRedirect
                  ];
                };
                gitNext = patchGit "next" gitNext {
                  attrOverrides = [
                    respectRustAfterDefaultOn
                    removeUnnecessaryRustPatch
                    removeAppliedPrecomposePatch
                    fixT1017AmbiguousRedirect
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
