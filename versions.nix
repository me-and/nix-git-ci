{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  channelName ? null,
}:
let
  baseData = {
    next = {
      rev = "3baa7cb742e267e07c93c00c15fa04107b8e9fab";
      hash = "sha256-LC1GJg+aKN2uagtPPJxg9F7PGCOlAINhFYFWwaeicj0=";
      version = "2.51.0.362.g3baa7cb742";

      # TODO Remove these once they're no longer included in any Nixpkgs
      # channel I care about building against.
      #
      # TODO Set things up so that I can have the overrides depend on the
      # channel I'm building against, as at time of writing I believe none of
      # these changes are necessary for nixpkgs-unstable, or at least they
      # won't be once the current staging branch is merged.
      extraOverride = prevAttrs: {
        patches = map (
          p:
          if baseNameOf p == "git-send-email-honor-PATH.patch" then
            ./git-send-email-honor-PATH-fixed.patch
          else
            p
        ) prevAttrs.patches;
        # Bit of a hack to remove the bits I care about without rewriting the
        # entire postInstall stage.
        postInstall =
          builtins.replaceStrings
            [
              "\nrm -r contrib/hooks/multimail"
              "\nmkdir -p $out/share/git-core/contrib"
              "\ncp -a contrib/hooks/ $out/share/git-core/contrib/"
              "\nsubstituteInPlace $out/share/git-core/contrib/hooks/pre-auto-gc-battery \\"
              "\n  --replace ' grep' ' /nix/store/"
            ]
            [
              ""
              ""
              ""
              ""
              "\n# REMOVED FOR EXPEDIENCE"
            ]
            prevAttrs.postInstall;
      };
      priority = 2;
    };
    master = {
      rev = "42bc22449512d0a5ce43155d48ee6adf278adcda";
      hash = "sha256-AcDFNwlwdYbOoN4nWid6dU7HjHB9Oczyqj7GpDskvE0=";
      version = "2.51.0.140.g42bc224495";
      extraOverride = prevAttrs: {
        patches = [
          ./t1517-test-installed.patch
        ]
        ++ map (
          p:
          if baseNameOf p == "git-send-email-honor-PATH.patch" then
            ./git-send-email-honor-PATH-fixed.patch
          else
            p
        ) prevAttrs.patches;
        # Bit of a hack to remove the bits I care about without rewriting the
        # entire postInstall stage.
        postInstall =
          builtins.replaceStrings
            [
              "\nrm -r contrib/hooks/multimail"
              "\nmkdir -p $out/share/git-core/contrib"
              "\ncp -a contrib/hooks/ $out/share/git-core/contrib/"
              "\nsubstituteInPlace $out/share/git-core/contrib/hooks/pre-auto-gc-battery \\"
              "\n  --replace ' grep' ' /nix/store/"
            ]
            [
              ""
              ""
              ""
              ""
              "\n# REMOVED FOR EXPEDIENCE"
            ]
            prevAttrs.postInstall;
      };
      priority = 1;
    };
    "maint-2.51" = {
      rev = "c44beea485f0f2feaf460e2ac87fdd5608d63cf0";
      hash = "sha256-vMjFXlOVs2OgNGn/t32Quwqo7qLYfgPaAka048qQ42g=";
      version = "2.51.0";
      extraOverride = prevAttrs: {
        patches = map (
          p:
          if baseNameOf p == "git-send-email-honor-PATH.patch" then
            ./git-send-email-honor-PATH-fixed.patch
          else
            p
        ) prevAttrs.patches;
        postInstall =
          builtins.replaceStrings
            [
              "\nrm -r contrib/hooks/multimail"
              "\nmkdir -p $out/share/git-core/contrib"
              "\ncp -a contrib/hooks/ $out/share/git-core/contrib/"
              "\nsubstituteInPlace $out/share/git-core/contrib/hooks/pre-auto-gc-battery \\"
              "\n  --replace ' grep' ' /nix/store/"
            ]
            [
              ""
              ""
              ""
              ""
              "\n# REMOVED FOR EXPEDIENCE"
            ]
            prevAttrs.postInstall;
      };
      priority = 3;
    };
    "maint-2.50" = {
      rev = "f368df439b31b422169975cc3c95f7db6a46eada";
      hash = "sha256-Up7l/879PSvA8ntpjdnmBUefK3l/B8rQi+qvGiS50iU=";
      version = "2.50.1.11.gf368df439b";
      priority = 4;
    };
  };
in
if channelName == null then
  builtins.mapAttrs (n: v: throw "You should only be looking at the names!") baseData
else
  builtins.mapAttrs (n: v: v // { safeName = builtins.replaceStrings [ "." ] [ "_" ] n; }) baseData
