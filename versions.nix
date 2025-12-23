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
  baseData = {
    next = {
      rev = "ee94076814604c8c59c7363bed60c934e31b9296";
      hash = "sha256-KoEFBYmgZSjLq+XZS+MoTVRXaLZlMaZRSZfsBJFaRxY=";
      version = "2.52.0.392.gee94076814";

      extraOverride = prevAttrs: {
        patches =
          (prevAttrs.patches or [])
          ++ [(pkgs.fetchurl {
                name = "expect-gui--askyesno-failure-in-t1517.patch";
                    url = "https://lore.kernel.org/git/20251201031040.1120091-1-brianmlyles@gmail.com/raw";
                        hash = "sha256-vvhbvg74OIMzfksHiErSnjOZ+W0M/T9J8GOQ4E4wKbU=";
                          })];
      };

      priority = 2;
    };
    master = {
      rev = "66ce5f8e8872f0183bb137911c52b07f1f242d13";
      hash = "sha256-USDTwYFYATJIkoDzwgrXp/xtSDXbBrHhT0IMDsBNYVg=";
      version = "2.52.0.318.g66ce5f8e88";

      extraOverride = prevAttrs: {
        patches =
          (prevAttrs.patches or [])
          ++ [(pkgs.fetchurl {
                name = "expect-gui--askyesno-failure-in-t1517.patch";
                    url = "https://lore.kernel.org/git/20251201031040.1120091-1-brianmlyles@gmail.com/raw";
                        hash = "sha256-vvhbvg74OIMzfksHiErSnjOZ+W0M/T9J8GOQ4E4wKbU=";
                          })];
      };

      priority = 1;
    };
    "maint-2.52" = {
      rev = "9a2fb147f2c61d0cab52c883e7e26f5b7948e3ed";
      hash = "sha256-2TMwVrb1PIxQSOnl2dR9EzMsSdVvfX5Z9HIpbEaxX94=";
      version = "2.52.0";

      extraOverride = prevAttrs: {
        patches =
          (prevAttrs.patches or [])
          ++ [(pkgs.fetchurl {
                name = "expect-gui--askyesno-failure-in-t1517.patch";
                    url = "https://lore.kernel.org/git/20251201031040.1120091-1-brianmlyles@gmail.com/raw";
                        hash = "sha256-vvhbvg74OIMzfksHiErSnjOZ+W0M/T9J8GOQ4E4wKbU=";
                          })];
      };

      priority = 3;
    };
    "maint-2.51" = {
      rev = "bb5c624209fcaebd60b9572b2cc8c61086e39b57";
      hash = "sha256-2aOM0jlatuIlxngQyOkkZQ/b8mvuJ9jxUgPduCEyDrk=";
      version = "2.51.2";
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
