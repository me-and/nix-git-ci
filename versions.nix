{
  next = {
    rev = "951bdd6678471b30baae4fa3f277a13238dc9556";
    hash = "sha256-Ek8pXGbTunH9t3r8q+E4Nmp6XQ3jqrVVQ95yBw9KEY4=";
    version = "2.50.0.rc2.752.g951bdd6678";
    extraOverride = prevAttrs: {
      patches = map (
        p:
        if baseNameOf p == "git-send-email-honor-PATH.patch" then
          ./git-send-email-honor-PATH-fixed.patch
        else
          p
      ) prevAttrs.patches;
    };
  };
  master = {
    rev = "f1ca98f609f9a730b9accf24e5558a10a0b41b6c";
    hash = "sha256-MvcAxAqZHBafEW5BTFawgNX6DhwRylxU3jg0/rfXaNQ=";
    version = "2.50.0.rc2.48.gf1ca98f609";
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
