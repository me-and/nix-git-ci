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
  t8020Patch = pkgs.fetchurl {
    name = "last-modified-fix-bug-caused-by-inproper-initialized-memory.patch";
    url = "https://lore.kernel.org/git/20251128-toon-big-endian-ci-v1-1-80da0f629c1e@iotcl.com/raw";
    hash = "sha256-WdewOwD7hMhnahhUUEYAlM58tT3MkxUlBa3n8IwrESU=";
  };

  addPatches = toAdd: patches: patches ++ builtins.filter (p: !builtins.elem p patches) toAdd;
  addPatch = patch: addPatches [ patch ];
  removePatches = toRemove: builtins.filter (p: !builtins.elem p toRemove);
  removePatch = patch: removePatches [ patch ];

  baseData = {
    next = {
      rev = "1b296b0f55885fa8fc649c4b31c37f3d86f3f9cf";
      hash = "sha256-g3llhvU+0xVP4JQdBOp/l3PoULl3uwmoasXtKpou2qY=";
      version = "2.54.0.rc2.535.g1b296b0f55";

      extraOverrideAttrs = prevAttrs: {
        patches = addPatch t1517Patch (removePatch t8020Patch prevAttrs.patches);
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
      rev = "e8955061076952cc5eab0300424fc48b601fe12d";
      hash = "sha256-c1S7AN9u7wSeUzz8r3CrP8o6lTh+J64uya59D9yC80I=";
      version = "2.54.0.rc2.9.ge895506107";

      extraOverrideAttrs = prevAttrs: {
        patches = addPatch t1517Patch (removePatch t8020Patch prevAttrs.patches);
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
    "maint-2.53" = {
      rev = "67ad42147a7acc2af6074753ebd03d904476118f";
      hash = "sha256-ChyfKmYW+VimCXr0CTvnkgBgY+fauVsBK0rbIwiDdvc=";
      version = "2.53.0";

      extraOverrideAttrs = prevAttrs: {
        patches = addPatch t1517Patch (removePatch t8020Patch prevAttrs.patches);
      };

      # TODO Remove this: it's only necessary as of 4580bcd235 (osxkeychain:
      # avoid incorrectly skipping store operation, 2025-11-14), and I expect
      # someone with a Darwin system will be able to make it work as soon as
      # there's an actual release that has that change.
      extraOverride = {
        osxkeychainSupport = false;
      };

      priority = 3;
    };
    "maint-2.52" = {
      rev = "9a2fb147f2c61d0cab52c883e7e26f5b7948e3ed";
      hash = "sha256-2TMwVrb1PIxQSOnl2dR9EzMsSdVvfX5Z9HIpbEaxX94=";
      version = "2.52.0";

      extraOverrideAttrs = prevAttrs: {
        patches = addPatch t1517Patch (removePatch t8020Patch prevAttrs.patches);
      };

      priority = 4;
    };
    "maint-2.51" = {
      rev = "bb5c624209fcaebd60b9572b2cc8c61086e39b57";
      hash = "sha256-2aOM0jlatuIlxngQyOkkZQ/b8mvuJ9jxUgPduCEyDrk=";
      version = "2.51.2";

      extraOverrideAttrs = prevAttrs: {
        patches = removePatches [ t1517Patch t8020Patch ] prevAttrs.patches;
      };

      priority = 5;
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
