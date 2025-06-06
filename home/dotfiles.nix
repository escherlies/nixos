# Motivation
# For stuff that frequently change, i.e. my vscode settings,
# I just want to have normal but synced Dotfiles :)
{ config, ... }:
let
  # projectRoot helper
  projectRoot =
    fromProjectRoot:
    # This repo lives always in ~/nixos
    config.lib.file.mkOutOfStoreSymlink ("${config.home.homeDirectory}/nixos/${fromProjectRoot}");

  vscodePackage = "Code"; # Code | VSCodium
in
{

  # VSCode
  home.file."vscode-settings" = {
    source = projectRoot "config/vscode/settings.json";
    target = ".config/${vscodePackage}/User/settings.json";
    force = true;
  };
  home.file."vscode-keybindings" = {
    source = projectRoot "config/vscode/keybindings.json";
    target = ".config/${vscodePackage}/User/keybindings.json";
    force = true;
  };

  # Kitty (additional)
  home.file.".config/kitty/dark-theme.auto.conf".source =
    projectRoot "config/kitty/dark-theme.auto.conf";
  home.file.".config/kitty/light-theme.auto.conf".source =
    projectRoot "config/kitty/light-theme.auto.conf";

}
