{
  lib,
  baseGit,
  versionData,
  fetchFromGitHub,
  updateScript,
  autoconf,
  stdenv,
  gnupatch,
  withRust,
}:
let
  owner = "gitster";
  repo = "git";
  localSrcName = "git-src"; # TODO is this necessary?

  # TODO Remove the conditional here once all the Nixpkgs versions I care about
  # have the option to support Rust.  Currently this is a bit misleading, as
  # we'll end up with the "withRust" and "withoutRust" versions of those
  # packages being identical, but they'll be identical from a derivation
  # perspective, too, so it won't make any difference.
  baseGit' =
    if withRust == null then
      baseGit
    else if baseGit.override.__functionArgs ? rustSupport then
      baseGit.override { rustSupport = withRust; }
    else
      baseGit;

  newGit = baseGit'.overrideAttrs (prevAttrs: {
    inherit (versionData) version;

    src = fetchFromGitHub {
      inherit owner repo;
      inherit (versionData) rev hash;
      name = localSrcName;
      fetchSubmodules = false;
      deepClone = true;
      fetchTags = true;
      preFetch = "export NIX_PREFETCH_GIT_CHECKOUT_HOOK=${lib.escapeShellArg "${updateScript}/libexec/prep-git-src.sh \"$dir\""}";
    };

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

  extraOverride = versionData.extraOverride or { };
  extraOverrideAttrs = versionData.extraOverrideAttrs or { };
in
(newGit.overrideAttrs (versionData.extraOverrideAttrs or { })).override extraOverride
