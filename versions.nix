{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  channel ? null,
}:
let
  allVersions = {
    # TODO Re-enable the next branch
    # next = {
    #   rev = "dddb2275d413451f7a01ff3f6c08fe0c6ce8f7b9";
    #   hash = "sha256-Or+1x+nGKJCvCRQfT0JytkOoQJICp1DgMm7oazVAHgw=";
    #   version = "2.51.0.rc2.237.gdddb2275d4";
    #   extraOverride = prevAttrs: {
    #     patches = map (
    #       p:
    #       if baseNameOf p == "git-send-email-honor-PATH.patch" then
    #         ./git-send-email-honor-PATH-fixed.patch
    #       else
    #         p
    #     ) prevAttrs.patches;
    #     # Bit of a hack to remove the bits I care about without rewriting the
    #     # entire postInstall stage.
    #     postInstall =
    #       builtins.replaceStrings
    #         [
    #           "\nrm -r contrib/hooks/multimail"
    #           "\nmkdir -p $out/share/git-core/contrib"
    #           "\ncp -a contrib/hooks/ $out/share/git-core/contrib/"
    #           "\nsubstituteInPlace $out/share/git-core/contrib/hooks/pre-auto-gc-battery \\"
    #           "\n  --replace ' grep' ' /nix/store/"
    #         ]
    #         [
    #           ""
    #           ""
    #           ""
    #           ""
    #           "\n# REMOVED FOR EXPEDIENCE"
    #         ]
    #         prevAttrs.postInstall;
    #   };
    # };
    master = {
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
