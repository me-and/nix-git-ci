{
  pkgs ? import <nixpkgs> { },
}:
let
  makeGitFrom = git: pkgs.callPackage ./git.nix { inherit git; };
in
pkgs.lib.genAttrs [ "git" "gitFull" "gitSVN" "gitMinimal" ] (
  name: makeGitFrom (builtins.getAttr name pkgs)
)
