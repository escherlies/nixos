{ pkgs, ... }:

{
  # Enable Neovim
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    extraConfig = ''
      set number
      set relativenumber
      set colorcolumn=80
    '';
  };
}
