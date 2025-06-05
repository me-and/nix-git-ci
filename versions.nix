{
  next = {
    rev = "fc6ec28a5d7844ff134d388edf5eb272d1cf11e9";
    hash = "sha256-QA8yDZU2HEM5DiYRDzD3nK2DGZuRyYnr9TvdfWjEk08=";
    version = "2.50.0.rc1.729.gfc6ec28a5d";
  };
  master = {
    rev = "14de3eb34435db79c6e7edc8082c302a26a8330a";
    hash = "sha256-kji6kqWJPCYyFK9l6ATdYytUo7hC80UuwqJTnHg1y9c=";
    version = "2.50.0.rc1.75.g14de3eb344";
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
