{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  channelName,
}:
{
  git = {
    priority = 1;
  };
}
