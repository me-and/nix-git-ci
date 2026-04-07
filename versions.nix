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
      rev = "7a70817efa3735665c323d2a970584bff018b33d";
      hash = "sha256-HT0/C+PLpMgwX7Uk1BugCqPsq2Skv0lmaaOyeL9IbqM=";
      version = "2.54.0.rc0.664.g7a70817efa";

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
      rev = "1adf5bca8c3cf778103548b9355777cf2d12efdd";
      hash = "sha256-nGm4+q0QdYNX7grSwtUoIaFanWz1rGWYQ32cDryZxvo=";
      version = "2.54.0.rc0.104.g1adf5bca8c";

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
