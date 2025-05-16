{
  programs.git = {
    enable = true;
    userName = "Enrico Scherlies";
    userEmail = "e.scherlies@pm.me";
    ignores = [
      ".note.*"
      ".vscode"
      ".DS_Store"
      ".notes"
      "**/__ignore__*"

    ];

    extraConfig = {
      init.defaultBranch = "main";
    };

    lfs.enable = true;

    signing = {
      format = "ssh";
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };

    difftastic.enable = true;
  };
}
