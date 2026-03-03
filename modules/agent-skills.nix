{ pkgs, ... }:
{
  # TODO: WIP will be imported via agent skills nix repo soon

  environment.systemPackages = with pkgs; [
    w3m
    lynx
    python314
  ];

  # environment.sessionVariables = {
  #   FOO = "Bar";
  # };
}
