{
  programs.git = {
    enable = true;
    ignores = [
      ".note.*"
      ".vscode"
      ".DS_Store"
      ".notes"
      "**/__ignore__*"
      ".claude"

    ];

    settings = {
      user.name = "Enrico Scherlies";
      user.email = "e.scherlies@pm.me";
      init.defaultBranch = "main";
    };

    aliases = {
      graph = "log --graph --oneline --all --decorate";
    };

    lfs.enable = true;

    signing = {
      format = "ssh";
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
  };

  programs.difftastic.enable = false;
}
