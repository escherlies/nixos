{ pkgs, ... }:

{
  programs = {
    neovim.enable = true;
    neovim.viAlias = true;
    neovim.vimAlias = true;
    neovim.defaultEditor = true;
    neovim.configure = {
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          vim-markdown
          bullets-vim
        ];
      };
      customRC = ''
        set number
        set relativenumber
        set clipboard=unnamedplus
        set foldlevel=99
      '';
    };
  };
}
