{
  next = {
    rev = "32ee0d3380b1e31900af1d3425960c0600d16a01";
    hash = "sha256-16AilQGn+UEveTfSj2Eu+LJSI+T6ofbCyk8ciB3daTE=";
    version = "2.50.0.rc1.593.g32ee0d3380";
  };
  master = {
    rev = "0d42fbd9a1f30c63cf0359a1c5aaa77020972f72";
    hash = "sha256-OyHD/O+PKayknaCznCN+T+0KCukHIPs74y/d/uBJ1R8=";
    version = "2.50.0.rc1.2.g0d42fbd9a1";
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
