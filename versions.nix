{
  next = {
    rev = "846fc57c9e4b739e87f307e88bdb8e68dace880c";
    hash = "sha256-6QyoR28Af6cWtZ/AMx8Rxr8rTK4Yidf1XdZCu2imAr0=";
    version = "2.50.0.rc0.629.g846fc57c9e";
  };
  master = {
    rev = "b07857f7dcffee4d3b428df8dce6c9b49a57c9c1";
    hash = "sha256-lXKDNm2zrFgLLAKTARWvjUamXU4+Iu0uMLGP+ZLOd2Y=";
    version = "2.50.0.rc0.61.gb07857f7dc";
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
