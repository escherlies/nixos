let
  shellAliases = {
    "zj" = "zellij";
  };
in
{
  programs.zellij.enable = true;
  programs.zellij.settings = {
    default_shell = "fish";
  };

  # only works in bash/zsh, not nushell
  home.shellAliases = shellAliases;
  programs.nushell.shellAliases = shellAliases;
}
