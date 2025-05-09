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

    difftastic.enable = true;
  };
}
