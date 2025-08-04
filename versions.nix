{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  channel ? null,
}:
let
  allVersions = {
    next = {
      rev = "3e08bea96f415556e219a4557eec4b445ad5bb66";
      hash = "sha256-YCh01r4Qrm5PEP0uTTku/SLgBL/g1tHYQKJ7Ev/hxtY=";
      version = "2.50.1.723.g3e08bea96f";
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
    };
    master = {
      rev = "721c9e5ce7c6fa4e1a33490f5e5a81eeee814021";
      hash = "sha256-Vo2tGmC4vOaGnbEtfBnsAEmqjWBAJuf0pJATbad45KY=";
      version = "2.51.0.rc0";
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
    };
    "maint-2.50" = {
      rev = "f368df439b31b422169975cc3c95f7db6a46eada";
      hash = "sha256-Up7l/879PSvA8ntpjdnmBUefK3l/B8rQi+qvGiS50iU=";
      version = "2.50.1.11.gf368df439b";
    };
  };
in
if channel == null then
  allVersions
else
  lib.filterAttrs (n: v: builtins.elem channel (v.channels or [ channel ])) allVersions
