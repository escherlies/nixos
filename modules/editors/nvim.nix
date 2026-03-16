{ pkgs, repoSubdir, ... }:

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
      # programs.neovim.configure sets VIMINIT which prevents neovim from
      # loading the user's init.lua. Source it explicitly so all settings
      # live in a native, bidirectional lua file in the repo.
      customRC = ''
        lua local f = vim.fn.stdpath("config") .. "/init.lua"; if vim.uv.fs_stat(f) then dofile(f) end
      '';
    };
  };

  # Symlink nvim config from the repo checkout into the user's XDG config dir.
  # This gives bidirectional editing — changes in the repo or in the config
  # dir are the same file, just like home-manager's mkOutOfStoreSymlink.
  system.activationScripts.nvim-config = ''
    for dir in /home/*/; do
      user=$(basename "$dir")
      id "$user" &>/dev/null || continue
      config_dir="$dir.config/nvim"
      target="$dir/${repoSubdir}/config/nvim/init.lua"
      [ -f "$target" ] || continue
      mkdir -p "$config_dir"
      ln -sf "$target" "$config_dir/init.lua"
    done
  '';
}
