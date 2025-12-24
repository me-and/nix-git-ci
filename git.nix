{
  lib,
  baseGit,
  versionData,
  fetchFromGitHub,
  updateScript,
  autoconf,
  stdenv,
  gnupatch,
}:
let
  owner = "gitster";
  repo = "git";
  localSrcName = "git-src"; # TODO is this necessary?

  # TODO Remove this: it's only necessary as of 4580bcd235 (osxkeychain: avoid
  # incorrectly skipping store operation, 2025-11-14), and I expect someone
  # with a Darwin system will be able to make it work as soon as there's an
  # actual release that has that change.
  baseGit' = baseGit.override { osxkeychainSupport = false; };

  newGit = baseGit'.overrideAttrs (prevAttrs: {
    inherit (versionData) version;

    src = fetchFromGitHub {
      inherit owner repo;
      inherit (versionData) rev hash;
      name = localSrcName;
      fetchSubmodules = false;
      deepClone = true;
      leaveDotGit = false;
      preFetch = "export NIX_PREFETCH_GIT_CHECKOUT_HOOK=${lib.escapeShellArg "${updateScript}/libexec/prep-git-src.sh \"$dir\""}";
    };

    # Needed as of v2.49.0-392-gfe35ce2ef8(contrib/completion: install Bash
    # completion, 2025-04-22)
    postInstall =
      builtins.replaceStrings
        [
          "\nln -s $out/share/git/contrib/completion/git-completion.bash $out/share/bash-completion/completions/git\n"
        ]
        [ "\n" ]
        prevAttrs.postInstall;

    # Don't leave .orig files just because the patch files didn't match
    # perfectly.
    patchFlags = "-p1 --no-backup-if-mismatch";

    # These *shouldn't* be necessary, but it looks like they're long-standing
    # failures that aren't being caught by the Darwin builds because the
    # mainline Darwin builds don't run the tests in the first place.
    preInstallCheck =
      (prevAttrs.preInstallCheck or "")
      + lib.optionalString stdenv.hostPlatform.isDarwin ''
        ${gnupatch}/bin/patch -p1 <${./t3900-mac.diff}
        disable_test t7900-maintenance 'start without GIT_TEST_MAINT_SCHEDULER'
      '';

    preConfigure = ''
      # Use a subshell for the extra preconfigure steps to avoid changing the
      # environment used for the rest of the Git build.
      (
          # Make the configure script using the same flags as for normal
          # build steps.
          local flagsArray=(
              ''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}}
              SHELL="$SHELL"
          )
          export PATH="${autoconf}/bin''${PATH:+:$PATH}"
          concatTo flagsArray makeFlags makeFlagsArray buildFlags buildFlagsArray
          make "''${flagsArray[@]}" configure
      )
    ''
    + (prevAttrs.preConfigure or "");
  });
in
newGit.overrideAttrs (versionData.extraOverride or { })
