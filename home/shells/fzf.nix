{ pkgs, config, ... }:

{
  programs.fzf = {
    enable = true;

    enableFishIntegration = true;

    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
    ];
  };
}
