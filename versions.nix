{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,

  # Channel name will be one of the following:
  # - null, meaning we want the full list of branches we care about, but none
  #   of them should evaluate.
  # - "all", meaning we want the full list of branches and their corresponding
  #   derivations, e.g. for use with the update-source-version script, but it's
  #   fine for some derivations to fail to build.
  # - A specific channel name string, in which case we want all the branches
  #   and their corresponding derivations that we want to build.
  channelName ? null,
}:
let
  t1517Patch = pkgs.fetchurl {
    name = "expect-gui--askyesno-failure-in-t1517.patch";
    url = "https://lore.kernel.org/git/20251201031040.1120091-1-brianmlyles@gmail.com/raw";
    hash = "sha256-vvhbvg74OIMzfksHiErSnjOZ+W0M/T9J8GOQ4E4wKbU=";
  };

  baseData = {
    next = {
      rev = "d81095ad136ff3cfd9c475f8ce1e2d0cf5f61c44";
      hash = "sha256-1uZ4YfIpZe8kH2iMyWR9f+tI4NSWB3OHU9AKeIgLZsY=";
      version = "2.53.0.rc1.225.gd81095ad13";

      extraOverrideAttrs = prevAttrs: {
        patches =
          prevAttrs.patches ++ lib.optional (!builtins.elem t1517Patch prevAttrs.patches) t1517Patch;
      };

      # TODO Remove this: it's only necessary as of 4580bcd235 (osxkeychain:
      # avoid incorrectly skipping store operation, 2025-11-14), and I expect
      # someone with a Darwin system will be able to make it work as soon as
      # there's an actual release that has that change.
      extraOverride = {
        osxkeychainSupport = false;
      };

      priority = 2;
    };
    master = {
      rev = "ea24e2c55433012a0a6c4ae947a87bc66404e484";
      hash = "sha256-zQ4IG3ckc9396Y+uIFXRw1Ea14DZo+hKNfMi8oQdVzc=";
      version = "2.53.0.rc1.65.gea24e2c554";

      extraOverrideAttrs = prevAttrs: {
        patches =
          prevAttrs.patches ++ lib.optional (!builtins.elem t1517Patch prevAttrs.patches) t1517Patch;
      };

      # TODO Remove this: it's only necessary as of 4580bcd235 (osxkeychain:
      # avoid incorrectly skipping store operation, 2025-11-14), and I expect
      # someone with a Darwin system will be able to make it work as soon as
      # there's an actual release that has that change.
      extraOverride = {
        osxkeychainSupport = false;
      };

      priority = 1;
    };
    "maint-2.52" = {
      rev = "9a2fb147f2c61d0cab52c883e7e26f5b7948e3ed";
      hash = "sha256-2TMwVrb1PIxQSOnl2dR9EzMsSdVvfX5Z9HIpbEaxX94=";
      version = "2.52.0";

      extraOverrideAttrs = prevAttrs: {
        patches =
          prevAttrs.patches ++ lib.optional (!builtins.elem t1517Patch prevAttrs.patches) t1517Patch;
      };

      priority = 3;
    };
    "maint-2.51" = {
      rev = "bb5c624209fcaebd60b9572b2cc8c61086e39b57";
      hash = "sha256-2aOM0jlatuIlxngQyOkkZQ/b8mvuJ9jxUgPduCEyDrk=";
      version = "2.51.2";

      extraOverrideAttrs = prevAttrs: {
        patches = lib.remove t1517Patch prevAttrs.patches;
      };

      priority = 4;
    };
  };

  addSafeNames = builtins.mapAttrs (
    n: v: v // { safeName = builtins.replaceStrings [ "." ] [ "_" ] n; }
  );
in
if channelName == null then
  builtins.mapAttrs (n: v: throw "You should only be looking at the names!") baseData
else
  addSafeNames baseData
