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
      rev = "c9366fe5a04afd4bfc01bb74b2471bc26509b37a";
      hash = "sha256-dqW5QntiykTgXAV3n/37w6O4WQ6zla9RYaPgKDrv3Gw=";
      version = "2.52.0.533.gc9366fe5a0";

      extraOverride = prevAttrs: {
        patches =
          prevAttrs.patches ++ lib.optional (!builtins.elem t1517Patch prevAttrs.patches) t1517Patch;
      };

      priority = 2;
    };
    master = {
      rev = "e0bfec3dfc356f7d808eb5ee546a54116b794397";
      hash = "sha256-JTyyMuN1MuoP4GaYkqebEGLJj0N9xionS3y9U+h/MWs=";
      version = "2.52.0.395.ge0bfec3dfc";

      extraOverride = prevAttrs: {
        patches =
          prevAttrs.patches ++ lib.optional (!builtins.elem t1517Patch prevAttrs.patches) t1517Patch;
      };

      priority = 1;
    };
    "maint-2.52" = {
      rev = "9a2fb147f2c61d0cab52c883e7e26f5b7948e3ed";
      hash = "sha256-2TMwVrb1PIxQSOnl2dR9EzMsSdVvfX5Z9HIpbEaxX94=";
      version = "2.52.0";

      extraOverride = prevAttrs: {
        patches =
          prevAttrs.patches ++ lib.optional (!builtins.elem t1517Patch prevAttrs.patches) t1517Patch;
      };

      priority = 3;
    };
    "maint-2.51" = {
      rev = "bb5c624209fcaebd60b9572b2cc8c61086e39b57";
      hash = "sha256-2aOM0jlatuIlxngQyOkkZQ/b8mvuJ9jxUgPduCEyDrk=";
      version = "2.51.2";

      extraOverride = prevAttrs: {
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
