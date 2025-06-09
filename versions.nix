{
  next = {
    rev = "5932e4b43abc488d9e2ecc2c0da51957d7b4f063";
    hash = "sha256-oqQGCZCRnUwSKBgFC1pjU86QFIVmoX4lF7mOvYA8Bi8=";
    version = "2.50.0.rc1.758.g5932e4b43a";
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
    rev = "4c0e625c091d4c648cec7319bafaed3cc81658e5";
    hash = "sha256-0ZUjBQ3a7CzJgwNT/0woMKEluqsW/bdCYiOREZTqXyc=";
    version = "2.50.0.rc2";
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
