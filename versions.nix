{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  channel ? null,
}:
let
  allVersions = {
    next = {
      rev = "097c87760abcd3f17c444cddbd6440096ce8d1c4";
      hash = "sha256-6quI/ge/qmw0E0jPU9EqTncYGkfJUaeY38U9wOec7qM=";
      version = "2.50.1.375.g097c87760a";
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
      rev = "a30f80fde927d70950b3b4d1820813480968fb0d";
      hash = "sha256-c6FjM764ZYkkO+WcylaixJNi4TYYdaqDiN7pTldcqHc=";
      version = "2.50.1.214.ga30f80fde9";
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
