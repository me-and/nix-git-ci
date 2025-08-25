{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  channelName,
}:
{
  git = {
    priority = 1;
  };
  gitFull = {
    priority = 2;
  };
  gitMinimal = {
    priority = 3;
  };
  gitSVN = {
    priority = 4;
  };
}
