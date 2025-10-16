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
      rev = "b6fe4d2222ed64f5cae7c56e9fd3361a4abbfb20";
      hash = "sha256-m8AyL4si32sbUj3oy8Z3Usq4Nbe72JD/44OCJ+NS/M4=";
      version = "2.51.1.821.gb6fe4d2222";

      # TODO Remove these once they're no longer included in any Nixpkgs
      # channel I care about building against.
      #
      # TODO Set things up so that I can have the overrides depend on the
      # channel I'm building against, as at time of writing I believe none of
      # these changes are necessary for nixpkgs-unstable, or at least they
      # won't be once the current staging branch is merged.
      extraOverride = prevAttrs: {
        patches =
          map (
            p:
            if baseNameOf p == "git-send-email-honor-PATH.patch" then
              ./git-send-email-honor-PATH-fixed.patch
            else
              p
          ) prevAttrs.patches
          ++ [ ./t1517.diff ];
        # Bit of a hack to remove the bits I care about without rewriting the
        # entire postInstall stage.
        postInstall =
          builtins.replaceStrings
            [
              "\nrm -r contrib/hooks/multimail"
              "\nmkdir -p $out/share/git-core/contrib"
              "\ncp -a contrib/hooks/ $out/share/git-core/contrib/"
              "\nsubstituteInPlace $out/share/git-core/contrib/hooks/pre-auto-gc-battery \\"
              "\n  --replace ' grep' ' /nix/store/"
            ]
            [
              ""
              ""
              ""
              ""
              "\n# REMOVED FOR EXPEDIENCE"
            ]
            prevAttrs.postInstall;
      };
      priority = 2;
    };
    master = {
      rev = "4253630c6f07a4bdcc9aa62a50e26a4d466219d1";
      hash = "sha256-Vye0ILHi9gyFrEGjbXghgqt7o3QW9tvJtzU/gXaFXU4=";
      version = "2.51.1.472.g4253630c6f";
      extraOverride = prevAttrs: {
        patches =
          map (
            p:
            if baseNameOf p == "git-send-email-honor-PATH.patch" then
              ./git-send-email-honor-PATH-fixed.patch
            else
              p
          ) prevAttrs.patches
          ++ [ ./t1517.diff ];
        # Bit of a hack to remove the bits I care about without rewriting the
        # entire postInstall stage.
        postInstall =
          builtins.replaceStrings
            [
              "\nrm -r contrib/hooks/multimail"
              "\nmkdir -p $out/share/git-core/contrib"
              "\ncp -a contrib/hooks/ $out/share/git-core/contrib/"
              "\nsubstituteInPlace $out/share/git-core/contrib/hooks/pre-auto-gc-battery \\"
              "\n  --replace ' grep' ' /nix/store/"
            ]
            [
              ""
              ""
              ""
              ""
              "\n# REMOVED FOR EXPEDIENCE"
            ]
            prevAttrs.postInstall;
      };
      priority = 1;
    };
    "maint-2.51" = {
      rev = "81f86aacc4eb74cdb9c2c8082d36d2070c666045";
      hash = "sha256-I0etaSEUWcO1RIaGA8n58HDFTWRcOToXpQPOo5fIB5I=";
      version = "2.51.1";
      extraOverride = prevAttrs: {
        patches = map (
          p:
          if baseNameOf p == "git-send-email-honor-PATH.patch" then
            ./git-send-email-honor-PATH-fixed.patch
          else
            p
        ) prevAttrs.patches;
        postInstall =
          builtins.replaceStrings
            [
              "\nrm -r contrib/hooks/multimail"
              "\nmkdir -p $out/share/git-core/contrib"
              "\ncp -a contrib/hooks/ $out/share/git-core/contrib/"
              "\nsubstituteInPlace $out/share/git-core/contrib/hooks/pre-auto-gc-battery \\"
              "\n  --replace ' grep' ' /nix/store/"
            ]
            [
              ""
              ""
              ""
              ""
              "\n# REMOVED FOR EXPEDIENCE"
            ]
            prevAttrs.postInstall;
      };
      priority = 3;
    };
    "maint-2.50" = {
      rev = "f368df439b31b422169975cc3c95f7db6a46eada";
      hash = "sha256-Up7l/879PSvA8ntpjdnmBUefK3l/B8rQi+qvGiS50iU=";
      version = "2.50.1.11.gf368df439b";
      priority = 4;
    };
  };

  addSafeNames = builtins.mapAttrs (
    n: v: v // { safeName = builtins.replaceStrings [ "." ] [ "_" ] n; }
  );
in
if channelName == null then
  builtins.mapAttrs (n: v: throw "You should only be looking at the names!") baseData

# Stop building maint-2.50 on unstable branches, as it's broken and
# unnecessary.
else if lib.hasSuffix "-unstable" channelName then
  addSafeNames (lib.filterAttrs (n: v: n != "maint-2.50") baseData)
else
  addSafeNames baseData
