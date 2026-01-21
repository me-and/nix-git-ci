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
      rev = "eba53bf80eb721f8e61c7b20a0dfc69f2d841278";
      hash = "sha256-x21vg4wtZnx/rh1MkqG9g5nCK8/9CrWyivZfvW0N3bM=";
      version = "2.53.0.rc1.217.geba53bf80e";

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
      rev = "83a69f19359e6d9bc980563caca38b2b5729808c";
      hash = "sha256-28ZDDOwYXxcgoMoG4mW00G62HWKTqzKlZllLj5dZ1YI=";
      version = "2.53.0.rc1";

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
