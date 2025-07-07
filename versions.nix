{
  next = {
    rev = "d6761aa22524d25e4201a1528ed332f8b82256ac";
    hash = "sha256-uRAq4m+aB73QeGbQ0BM9DK+A17VINlpXwp9k25e0btU=";
    version = "2.50.0.231.gd6761aa225";
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
    rev = "41905d60226a0346b22f0d0d99428c746a5a3b14";
    hash = "sha256-dlpUIcaVKZj29FHrIm/5XHrpXr3DFnZen9rZZLaTeD4=";
    version = "2.50.0.193.g41905d6022";
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
    rev = "d50a5e8939abfc07c2ff97ae72e9330939b36ee0";
    hash = "sha256-XRfoorZVqKk/LAH8ud5ddgPVXAVa86Z4edoq/MhxaWU=";
    version = "2.49.0.9.gd50a5e8939";
  };
}
