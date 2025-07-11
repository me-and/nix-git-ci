{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  channel ? null,
}:
let
  allVersions = {
    next = {
      rev = "cf940e82a113e874e1f6b1e115361b9b01291af3";
      hash = "sha256-SE6F3RjE5xoPRlzqJ7QLTLe9cg8Iym8tNXbZEVMA2JM=";
      version = "2.50.1.351.gcf940e82a1";
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
    # TODO these are failing because the patches applied for the more recent
    # branches don't apply here.  Need to work out how to handle that, which might
    # be something around using different nixpkgs versions corresponding to
    # different maintenance branches.
    #
    #  "maint-2.47" = {
    #    rev = "e1fbebe347426ef7974dc2198f8a277b7c31c8fe";
    #    hash = "sha256-h3nAt71GzT+g31Ww5hJXzlBV4Yiq8/otp2wJv0VwDaI=";
    #    version = "2.47.2";
    #  };
    #  "maint-2.48" = {
    #    rev = "f93ff170b93a1782659637824b25923245ac9dd1";
    #    hash = "sha256-W8eU04qSHy3j9Dg9inOQRtMtebW+T7BcpcCKhdikTow=";
    #    version = "2.48.1";
    #  };
    "maint-2.49" = {
      rev = "47243eeed1749662e7c62d879d451a9383a25158";
      hash = "sha256-YYq+XX/aP2nFxKDbE5INCgSMsp4DL00ROoQ7VqPzERE=";
      version = "2.49.1.9.g47243eeed1";
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
