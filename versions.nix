{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  channelName ? null,
}:
let
  baseData = {
    next = {
      rev = "15c5d4f767f655d8c09d24948ad0ab2a5e304793";
      hash = "sha256-3tYla/YKd48jPVv6VYl3pUf1xC9x5EvZdSfQXolIUEU=";
      version = "2.51.0.536.g15c5d4f767";

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
      rev = "ca2559c1d630eb4f04cdee2328aaf1c768907a9e";
      hash = "sha256-3YiMSsYEbMjWtrcZWzwEYw5NcaN2dV360XkFPhS3KQw=";
      version = "2.51.0.297.gca2559c1d6";
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
