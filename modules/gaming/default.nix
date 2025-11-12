{ config, lib, ... }:

with lib;

{
  options.modules.gaming = {
    enable = mkEnableOption "gaming support including Steam, gamescope, and gamemode";
  };

  config = mkIf config.modules.gaming.enable {
    # Enable Steam services
    programs.steam.enable = true;
    programs.steam.gamescopeSession.enable = true;

    programs.gamemode.enable = true;
  };
}
