{
  programs = {
    neovim.enable = true;
    neovim.viAlias = true;
    neovim.vimAlias = true;
    neovim.defaultEditor = true;
    neovim.configure = {
      customRC = ''
        set number
        set relativenumber
      '';
    };
  };
}
