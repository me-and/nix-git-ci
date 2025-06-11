{
  next = {
    rev = "1fc2a0284fe0c5c6cf60bd906769851270ab00a1";
    hash = "sha256-Efgs5p/1goss1drnRAJbsfnq69bfphJyIC9qpZ5mF3w=";
    version = "2.50.0.rc2.696.g1fc2a0284f";
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
    rev = "1e2677f66fb9e1de2ccaff6e136a3d53ee8d1aed";
    hash = "sha256-Pl2UFJD/TAi87vLD7RFRm8zSvEd+uFg3GJ9HN9DpX+I=";
    version = "2.50.0.rc2.1.g1e2677f66f";
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
