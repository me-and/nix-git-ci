{
  next = {
    rev = "7c01cdd2a944f0901323046e0dada7f3c0e6b8f1";
    hash = "sha256-8FhZ/IFDxwubo3ym5Jq332qtOrf91AfQgdKyBycX4E0=";
    version = "2.50.1.308.g7c01cdd2a9";
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
    rev = "038143def708a65455172a87432aee27da2d80c4";
    hash = "sha256-Z1fqbQb+p5nm1jyqiMHXy19ru810+v93HcCJtcEIdXw=";
    version = "2.50.1.194.g038143def7";
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
    rev = "d82adb61ba2fd11d8f2587fca1b6bd7925ce4044";
    hash = "sha256-pCt6GjGlVGF9TYM+eplgrNHP7/G0pXv/wKrbT8oZGg8=";
    version = "2.50.1";
  };
}
