# Motivation
# For stuff that frequently change, i.e. my vscode settings,
# I just want to have normal but synced Dotfiles :)
{ config, repoSubdir, ... }:
let
  # projectRoot helper
  projectRoot =
    fromProjectRoot:
    config.lib.file.mkOutOfStoreSymlink (
      "${config.home.homeDirectory}/${repoSubdir}/${fromProjectRoot}"
    );

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

  # Himalaya
  home.file.".config/himalaya/config.toml".source = projectRoot "config/himalaya/config.toml";

  # MIME type associations (bidirectional -- editable from ~/.config or the repo)
  home.file.".config/mimeapps.list".source = projectRoot "config/mimeapps.list";

}
